import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

type RawPlayer = {
  id: string
  name: string
  nationality_code?: string | null
  primary_position?: string | null
}

type EnrichedPlayer = RawPlayer & {
  clubs_preview: string[]
  popularity_score: number
  is_cell_relevant: boolean
}

function normalizeQuery(query: string): string {
  return query
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
}

function scorePlayer(player: EnrichedPlayer, normalized: string): number {
  const name = player.name.toLowerCase()
  let score = player.popularity_score

  if (player.is_cell_relevant) score += 300
  if (!normalized) return score

  if (name === normalized) score += 1000
  else if (name.startsWith(normalized)) score += 500
  else if (name.includes(normalized)) score += 200

  return score
}

async function enrichPlayers(
  supabase: ReturnType<typeof createClient>,
  players: RawPlayer[],
  rowClubId?: string | null,
  colClubId?: string | null,
): Promise<EnrichedPlayer[]> {
  if (players.length === 0) return []

  const ids = players.map((p) => p.id)

  const [{ data: careers }, { data: popularity }, intersectionIds] = await Promise.all([
    supabase
      .from('player_career_history')
      .select('player_id, appearances, clubs (short_name, name, is_top_club)')
      .in('player_id', ids)
      .eq('is_senior', true)
      .eq('is_youth', false)
      .eq('is_reserve', false),
    supabase
      .from('player_popularity')
      .select('player_id, global_selection_count')
      .in('player_id', ids),
    rowClubId && colClubId
      ? fetchIntersectionIds(supabase, ids, rowClubId, colClubId)
      : Promise.resolve(new Set<string>()),
  ])

  const clubsByPlayer = new Map<string, string[]>()
  for (const row of careers ?? []) {
    const playerId = row.player_id as string
    const club = row.clubs as {
      short_name?: string | null
      name?: string | null
      is_top_club?: boolean
    } | null
    if (!club) continue
    const label = (club.short_name || club.name || '').trim()
    if (!label) continue
    const list = clubsByPlayer.get(playerId) ?? []
    if (!list.includes(label)) list.push(label)
    clubsByPlayer.set(playerId, list)
  }

  const popByPlayer = new Map<string, number>()
  for (const row of popularity ?? []) {
    popByPlayer.set(row.player_id as string, (row.global_selection_count as number) ?? 0)
  }

  return players.map((player) => ({
    ...player,
    clubs_preview: (clubsByPlayer.get(player.id) ?? []).slice(0, 4),
    popularity_score: popByPlayer.get(player.id) ?? 0,
    is_cell_relevant: intersectionIds.has(player.id),
  }))
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

const SLUG_ALIAS_GROUPS: string[][] = [
  ['barcelona', 'fc-barcelona'],
  ['chelsea', 'chelsea-fc'],
  ['psg', 'paris-saintgermain', 'paris-saint-germain'],
  ['bayern-munich', 'bayern', 'fc-bayern-munchen', 'bayern-munchen'],
  ['manchester-united', 'man-utd', 'man-united', 'manchester-utd'],
  ['manchester-city', 'man-city'],
  ['arsenal-fc', 'arsenal'],
  ['liverpool-fc', 'liverpool'],
  ['inter-milan', 'inter'],
  ['atletico-madrid', 'atletico'],
  ['fc-porto', 'porto'],
  ['tottenham-hotspur', 'tottenham', 'spurs'],
]

function canonicalSlug(slug: string): string {
  for (const group of SLUG_ALIAS_GROUPS) {
    if (group.includes(slug)) return group[0]
  }
  return slug
}

async function resolveEquivalentClubIds(
  supabase: ReturnType<typeof createClient>,
  clubRef: string,
): Promise<string[]> {
  const { data, error } = await supabase.rpc('club_ids_equivalent_to', {
    p_club_ref: clubRef,
  })
  if (!error && Array.isArray(data) && data.length > 0) {
    return data as string[]
  }

  let slug = clubRef
  if (UUID_RE.test(clubRef)) {
    const { data: club } = await supabase
      .from('clubs')
      .select('slug')
      .eq('id', clubRef)
      .maybeSingle()
    if (!club?.slug) return [clubRef]
    slug = club.slug
  }

  const aliasSlugs = SLUG_ALIAS_GROUPS.find((g) => g.includes(slug)) ?? [slug]
  const { data: clubs } = await supabase.from('clubs').select('id').in('slug', aliasSlugs)
  const ids = new Set<string>()
  if (UUID_RE.test(clubRef)) ids.add(clubRef)
  for (const club of clubs ?? []) ids.add(club.id as string)
  return [...ids]
}

async function fetchIntersectionIds(
  supabase: ReturnType<typeof createClient>,
  playerIds: string[],
  rowClubId: string,
  colClubId: string,
): Promise<Set<string>> {
  const relevant = new Set<string>()
  if (playerIds.length === 0) return relevant

  const [rowIds, colIds] = await Promise.all([
    resolveEquivalentClubIds(supabase, rowClubId),
    resolveEquivalentClubIds(supabase, colClubId),
  ])
  const rowSet = new Set(rowIds)
  const colSet = new Set(colIds)

  const { data } = await supabase
    .from('player_club_intersections')
    .select('player_id, club_a_id, club_b_id')
    .in('player_id', playerIds)

  for (const row of data ?? []) {
    const a = row.club_a_id as string
    const b = row.club_b_id as string
    const hasPair =
      (rowSet.has(a) && colSet.has(b)) || (rowSet.has(b) && colSet.has(a))
    if (hasPair) relevant.add(row.player_id as string)
  }

  // Materialized view may be stale; verify remaining candidates via RPC when available.
  const unchecked = playerIds.filter((id) => !relevant.has(id))
  if (unchecked.length === 0) return relevant

  const checks = await Promise.all(
    unchecked.slice(0, 20).map(async (playerId) => {
      const { data: ok, error } = await supabase.rpc('validate_player_intersection', {
        p_player_id: playerId,
        p_row_club_ref: rowClubId,
        p_col_club_ref: colClubId,
      })
      return !error && ok === true ? playerId : null
    }),
  )
  for (const playerId of checks) {
    if (playerId) relevant.add(playerId)
  }

  return relevant
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const start = performance.now()

  try {
    const url = new URL(req.url)
    const query = url.searchParams.get('q')?.trim() ?? ''
    const limit = Math.min(parseInt(url.searchParams.get('limit') ?? '20'), 50)
    const mode = url.searchParams.get('mode')
    const rowClubId = url.searchParams.get('row_club_id')
    const colClubId = url.searchParams.get('col_club_id')

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    if (mode === 'suggested' && rowClubId && colClubId) {
      const { data: intersectionRows } = await supabase.rpc('get_intersection_players', {
        p_row_club_id: rowClubId,
        p_col_club_id: colClubId,
      })

      const raw = ((intersectionRows ?? []) as RawPlayer[]).slice(0, limit)
      const suggested = await enrichPlayers(supabase, raw, rowClubId, colClubId)

      return new Response(
        JSON.stringify({
          results: [],
          suggested,
          latency_ms: Math.round(performance.now() - start),
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    if (query.length < 1) {
      const { data: popular } = await supabase
        .from('player_popularity')
        .select('players (id, name, nationality_code, primary_position)')
        .order('global_selection_count', { ascending: false })
        .limit(limit)

      const raw = (popular ?? []).map((p: { players: RawPlayer }) => p.players)
      const results = await enrichPlayers(supabase, raw, rowClubId, colClubId)

      let suggested: EnrichedPlayer[] = []
      if (rowClubId && colClubId) {
        const { data: intersectionRows } = await supabase.rpc('get_intersection_players', {
          p_row_club_id: rowClubId,
          p_col_club_id: colClubId,
        })
        suggested = await enrichPlayers(
          supabase,
          ((intersectionRows ?? []) as RawPlayer[]).slice(0, Math.min(limit, 12)),
          rowClubId,
          colClubId,
        )
      }

      return new Response(
        JSON.stringify({
          results,
          suggested,
          latency_ms: Math.round(performance.now() - start),
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const normalized = normalizeQuery(query)

    const { data: rawResults } = await supabase
      .from('players')
      .select('id, name, nationality_code, primary_position')
      .ilike('normalized_name', `%${normalized}%`)
      .limit(Math.min(limit * 3, 60))

    const enriched = await enrichPlayers(
      supabase,
      (rawResults ?? []) as RawPlayer[],
      rowClubId,
      colClubId,
    )
    const ranked = enriched
      .sort((a, b) => scorePlayer(b, normalized) - scorePlayer(a, normalized))
      .slice(0, limit)

    return new Response(
      JSON.stringify({
        results: ranked,
        suggested: [],
        latency_ms: Math.round(performance.now() - start),
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
