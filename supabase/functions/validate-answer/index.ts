import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

function tierFromUsage(pct: number): string {
  if (pct > 50) return 'common'
  if (pct > 25) return 'rare'
  if (pct > 10) return 'epic'
  if (pct > 3) return 'legendary'
  return 'mythic'
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const { row_club_id, col_club_id, player_id, puzzle_cell_id } = body

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: correct, error: validateError } = await supabase.rpc(
      'validate_player_intersection',
      {
        p_player_id: player_id,
        p_row_club_ref: String(row_club_id),
        p_col_club_ref: String(col_club_id),
      },
    )

    if (validateError) {
      console.error('validate_player_intersection failed:', validateError.message)
    }

    const isCorrect = !validateError && correct === true

    let usagePercentage = 0
    let rarityScore = 0
    const validCellId = puzzle_cell_id && UUID_RE.test(String(puzzle_cell_id))

    if (isCorrect && validCellId) {
      try {
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

        await supabase.rpc('increment_rarity_stat', {
          p_cell_id: puzzle_cell_id,
          p_player_id: player_id,
        }).catch(() => {/* optional RPC */})
      } catch {
        // Rarity is best-effort; a valid answer must still register as correct.
      }
    }

    const { data: player } = await supabase
      .from('players')
      .select('name')
      .eq('id', player_id)
      .maybeSingle()

    return new Response(
      JSON.stringify({
        correct: isCorrect,
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
