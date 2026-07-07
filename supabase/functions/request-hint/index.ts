import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

type HintType =
  | 'nationality'
  | 'position'
  | 'first_letter'
  | 'career_league'
  | 'retired_status'
  | 'career_club'

type PlayerRow = {
  id: string
  name: string
  nationality_code: string | null
  primary_position: string | null
}

function stableIndex(seed: string, length: number): number {
  let hash = 0
  for (let i = 0; i < seed.length; i++) {
    hash = (hash * 31 + seed.charCodeAt(i)) >>> 0
  }
  return length > 0 ? hash % length : 0
}

async function resolveClubIds(
  supabase: ReturnType<typeof createClient>,
  clubRef: string,
): Promise<string[]> {
  const { data: rpcIds } = await supabase.rpc('club_ids_equivalent_to', { p_club_ref: clubRef })
  if (Array.isArray(rpcIds) && rpcIds.length > 0) return rpcIds as string[]
  return [clubRef]
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const { row_club_id, col_club_id, puzzle_cell_id, session_id, hint_type } = body
    const userUuid = req.headers.get('x-user-uuid') ?? body.user_uuid ?? ''

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    if (session_id) {
      const { error: sessionError } = await supabase.rpc('assert_active_session', {
        p_session_id: session_id,
        p_user_uuid: userUuid || null,
      })
      if (sessionError) {
        const msg = sessionError.message ?? String(sessionError)
        return new Response(JSON.stringify({ error: msg }), {
          status: msg.includes('forbidden') ? 403 : 409,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    const type = (hint_type as HintType) ?? 'nationality'
    const adToken = body.ad_token ? String(body.ad_token) : ''
    const skipAdVerify = Deno.env.get('HINT_SKIP_AD') === 'true'

    if (!skipAdVerify) {
      const { data: isPremium } = userUuid
        ? await supabase.rpc('user_is_premium', { p_user_uuid: userUuid })
        : { data: false }
      if (!isPremium) {
        if (!adToken || !/^[0-9a-f-]{36}$/i.test(adToken)) {
          return new Response(JSON.stringify({ error: 'ad_token_required' }), {
            status: 403,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }
        const { data: consumed, error: consumeError } = await supabase.rpc(
          'consume_hint_ad_token',
          { p_token: adToken, p_user_uuid: userUuid || 'anonymous' },
        )
        if (consumeError || consumed !== true) {
          return new Response(JSON.stringify({ error: 'invalid_ad_token' }), {
            status: 403,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }
      }
    }

    const { data: validPlayers, error: validError } = await supabase.rpc(
      'get_intersection_players',
      { p_row_club_id: row_club_id, p_col_club_id: col_club_id },
    )

    if (validError) throw validError

    const players = (validPlayers ?? []) as PlayerRow[]

    if (players.length === 0) {
      return new Response(
        JSON.stringify({ hint_type, hint_value: 'No hint available' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const seed = `${session_id ?? ''}:${puzzle_cell_id ?? ''}`
    const sample = players[stableIndex(seed, players.length)]

    const rowIds = await resolveClubIds(supabase, String(row_club_id))
    const colIds = await resolveClubIds(supabase, String(col_club_id))
    const excludeIds = new Set([...rowIds, ...colIds])

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
      case 'career_league': {
        const { data: careers } = await supabase
          .from('player_career_history')
          .select('club_id, clubs (league_name, short_name, name)')
          .eq('player_id', sample.id)
          .eq('is_senior', true)
          .eq('is_youth', false)
          .eq('is_reserve', false)

        const leagues = new Set<string>()
        for (const row of careers ?? []) {
          const club = row.clubs as { league_name?: string; short_name?: string; name?: string } | null
          const league = club?.league_name?.trim()
          if (league) leagues.add(league)
        }
        hintValue = leagues.size > 0 ? [...leagues][0] : 'Unknown league'
        break
      }
      case 'retired_status': {
        const { data: careers } = await supabase
          .from('player_career_history')
          .select('end_date')
          .eq('player_id', sample.id)
          .eq('is_senior', true)
          .eq('is_youth', false)
          .eq('is_reserve', false)

        const today = new Date().toISOString().split('T')[0]
        const active = (careers ?? []).some((c) => !c.end_date || c.end_date >= today)
        hintValue = active ? 'Active' : 'Retired'
        break
      }
      case 'career_club': {
        const { data: careers } = await supabase
          .from('player_career_history')
          .select('club_id, clubs (short_name, name)')
          .eq('player_id', sample.id)
          .eq('is_senior', true)
          .eq('is_youth', false)
          .eq('is_reserve', false)

        const extras: string[] = []
        for (const row of careers ?? []) {
          if (excludeIds.has(row.club_id as string)) continue
          const club = row.clubs as { short_name?: string; name?: string } | null
          const label = club?.short_name ?? club?.name
          if (label) extras.push(label)
        }
        hintValue = extras.length > 0 ? extras[stableIndex(seed + ':club', extras.length)] : 'Unknown club'
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
      ).catch(() => {/* optional */})
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
