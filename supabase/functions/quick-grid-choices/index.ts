import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

function shuffle<T>(items: T[]): T[] {
  const arr = [...items]
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[arr[i], arr[j]] = [arr[j], arr[i]]
  }
  return arr
}

type PlayerRow = {
  id: string
  name: string
  nationality_code?: string | null
  primary_position?: string | null
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const action = url.searchParams.get('action') ?? 'choices'
    const rowClubId = url.searchParams.get('row_club_id') ?? ''
    const colClubId = url.searchParams.get('col_club_id') ?? ''

    if (!rowClubId || !colClubId || !UUID_RE.test(rowClubId) || !UUID_RE.test(colClubId)) {
      return new Response(JSON.stringify({ ok: false, reason: 'invalid_clubs' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    if (action === 'eliminate') {
      const rawIds = (url.searchParams.get('choice_ids') ?? '')
        .split(',')
        .map((s) => s.trim())
        .filter((s) => UUID_RE.test(s))
      if (rawIds.length < 2) {
        return new Response(JSON.stringify({ ok: false, reason: 'need_choices' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      const checks = await Promise.all(
        rawIds.map(async (playerId) => {
          const { data: ok, error } = await supabase.rpc('validate_player_intersection', {
            p_player_id: playerId,
            p_row_club_ref: rowClubId,
            p_col_club_ref: colClubId,
          })
          return { playerId, correct: !error && ok === true }
        }),
      )
      const wrong = checks.filter((c) => !c.correct).map((c) => c.playerId)
      if (wrong.length === 0) {
        return new Response(JSON.stringify({ ok: false, reason: 'no_wrong_choice' }), {
          status: 409,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
      const removeId = wrong[Math.floor(Math.random() * wrong.length)]
      return new Response(JSON.stringify({ ok: true, remove_player_id: removeId }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const limit = Math.min(parseInt(url.searchParams.get('limit') ?? '5', 10) || 5, 8)

    const { data: correctRows, error: correctError } = await supabase.rpc(
      'get_intersection_players',
      { p_row_club_id: rowClubId, p_col_club_id: colClubId },
    )

    if (correctError) {
      return new Response(JSON.stringify({ ok: false, error: correctError.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const correctPool = shuffle((correctRows ?? []) as PlayerRow[])
    if (correctPool.length === 0) {
      return new Response(JSON.stringify({ ok: false, reason: 'no_correct_players' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const correct = correctPool[0]
    const correctIds = new Set(correctPool.map((p) => p.id))

    const { data: popular } = await supabase
      .from('player_popularity')
      .select('players (id, name, nationality_code, primary_position)')
      .order('global_selection_count', { ascending: false })
      .limit(40)

    const distractorCandidates: PlayerRow[] = []
    for (const row of popular ?? []) {
      const p = (row as { players: PlayerRow }).players
      if (!p?.id || correctIds.has(p.id)) continue
      distractorCandidates.push(p)
    }

    const verified: PlayerRow[] = []
    for (const candidate of shuffle(distractorCandidates).slice(0, 16)) {
      if (verified.length >= limit - 1) break
      const { data: ok, error } = await supabase.rpc('validate_player_intersection', {
        p_player_id: candidate.id,
        p_row_club_ref: rowClubId,
        p_col_club_ref: colClubId,
      })
      if (!error && ok === true) continue
      verified.push(candidate)
    }

    while (verified.length < limit - 1) {
      const next = distractorCandidates.find((d) => !verified.some((v) => v.id === d.id) && !correctIds.has(d.id))
      if (!next) break
      verified.push(next)
    }

    const choices = shuffle([
      {
        id: correct.id,
        name: correct.name,
        nationality_code: correct.nationality_code ?? null,
        primary_position: correct.primary_position ?? null,
      },
      ...verified.slice(0, limit - 1).map((d) => ({
        id: d.id,
        name: d.name,
        nationality_code: d.nationality_code ?? null,
        primary_position: d.primary_position ?? null,
      })),
    ])

    return new Response(JSON.stringify({ ok: true, choices }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ ok: false, error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
