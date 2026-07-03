import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

type HintType = 'nationality' | 'position' | 'first_letter'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { row_club_id, col_club_id, puzzle_cell_id, session_id, hint_type } = await req.json()

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: validPlayers, error: validError } = await supabase.rpc(
      'get_intersection_players',
      { p_row_club_id: row_club_id, p_col_club_id: col_club_id },
    )

    if (validError) throw validError

    const players = (validPlayers ?? []) as Array<{
      id: string
      name: string
      nationality_code: string | null
      primary_position: string | null
    }>

    if (players.length === 0) {
      return new Response(
        JSON.stringify({ hint_type, hint_value: 'No hint available' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const sample = players[Math.floor(Math.random() * players.length)]
    const type = (hint_type as HintType) ?? 'nationality'

    let hintValue = ''
    switch (type) {
      case 'nationality':
        hintValue = sample.nationality_code ?? 'Unknown'
        break
      case 'position':
        hintValue = sample.primary_position ?? 'Unknown'
        break
      case 'first_letter': {
        const first = sample.name.trim()[0]?.toUpperCase() ?? '?'
        const length = sample.name.replace(/[^a-zA-Z]/g, '').length
        hintValue = `${first}${' _'.repeat(Math.max(length - 1, 3))}`.trim()
        break
      }
    }

    if (session_id && puzzle_cell_id) {
      await supabase.from('session_hints').upsert(
        {
          session_id,
          puzzle_cell_id,
          hint_type: type,
          hint_value: hintValue,
        },
        { onConflict: 'session_id,puzzle_cell_id,hint_type' },
      )
    }

    return new Response(
      JSON.stringify({ hint_type: type, hint_value: hintValue }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
