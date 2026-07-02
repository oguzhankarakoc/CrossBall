import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

function tierFromUsage(pct: number): string {
  if (pct > 50) return 'common'
  if (pct > 25) return 'rare'
  if (pct > 10) return 'epic'
  if (pct > 3) return 'legendary'
  return 'mythic'
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const { row_club_id, col_club_id, player_id, puzzle_cell_id, session_id } = body

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Check intersection via career history
    const { data: careers } = await supabase
      .from('player_career_history')
      .select('club_id')
      .eq('player_id', player_id)
      .eq('is_senior', true)
      .eq('is_youth', false)
      .eq('is_reserve', false)
      .in('club_id', [row_club_id, col_club_id])

    const clubIds = new Set((careers ?? []).map((c: { club_id: string }) => c.club_id))
    const correct = clubIds.has(row_club_id) && clubIds.has(col_club_id)

    let usagePercentage = 0
    let rarityScore = 0

    if (correct && puzzle_cell_id) {
      const { data: rarity } = await supabase
        .from('rarity_stats')
        .select('usage_percentage, selection_count')
        .eq('puzzle_cell_id', puzzle_cell_id)
        .eq('player_id', player_id)
        .maybeSingle()

      usagePercentage = rarity?.usage_percentage ?? 0

      const { count: totalSelections } = await supabase
        .from('rarity_stats')
        .select('*', { count: 'exact', head: true })
        .eq('puzzle_cell_id', puzzle_cell_id)

      if (!rarity && totalSelections !== null) {
        usagePercentage = totalSelections > 0 ? 0 : 100
      }

      rarityScore = Math.max(0, 100 - usagePercentage)

      // Increment selection count
      await supabase.rpc('increment_rarity_stat', {
        p_cell_id: puzzle_cell_id,
        p_player_id: player_id,
      }).catch(() => {/* optional RPC */})
    }

    const { data: player } = await supabase
      .from('players')
      .select('name')
      .eq('id', player_id)
      .single()

    return new Response(
      JSON.stringify({
        correct,
        player_name: player?.name ?? '',
        usage_percentage: usagePercentage,
        rarity_tier: tierFromUsage(usagePercentage),
        rarity_score: rarityScore,
        already_used_in_session: false,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
