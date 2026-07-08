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
  identity_key?: string | null
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

const SURNAME_PARTICLES = new Set([
  'de', 'da', 'do', 'dos', 'das', 'van', 'von', 'der', 'di', 'del', 'la', 'le', 'mc', 'mac',
])

function significantSurname(parts: string[]): string {
  for (let i = parts.length - 1; i >= 0; i--) {
    if (!SURNAME_PARTICLES.has(parts[i])) return parts[i]
  }
  return parts[parts.length - 1]
}

function prepareNameForIdentity(name: string): string {
  return name.replace(/\.(?=\S)/g, '. ')
}

function playerIdentityKey(name: string): string {
  const normalized = normalizeQuery(prepareNameForIdentity(name))
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
  const parts = normalized.split(/\s+/).filter(Boolean)
  if (parts.length === 0) return normalized
  const surname = significantSurname(parts)
  if (parts.length === 1) return surname
  const first = parts[0].replace(/\.$/, '')
  const token = first.charAt(0)
  return `${surname}|${token}`
}

function dedupeKeyForPlayer(player: EnrichedPlayer): string {
  // Always derive from display name — DB identity_key may be stale (e.g. Z.Ibrahimovic → zibrahimovic).
  return playerIdentityKey(player.name)
}

function playerCompletenessScore(player: EnrichedPlayer): number {
  let score = (player.clubs_preview?.length ?? 0) * 5
  if (player.nationality_code) score += 20
  if (player.primary_position) score += 10
  score += player.name.length
  if (!/^[A-Z]\.\s/.test(player.name)) score += 15
  return score
}

function mergeEnrichedPlayers(a: EnrichedPlayer, b: EnrichedPlayer): EnrichedPlayer {
  const primary =
    playerCompletenessScore(a) >= playerCompletenessScore(b) ? a : b
  const secondary = primary === a ? b : a
  const clubs = [...new Set([...(primary.clubs_preview ?? []), ...(secondary.clubs_preview ?? [])])]
  return {
    ...primary,
    nationality_code: primary.nationality_code ?? secondary.nationality_code ?? null,
    primary_position: primary.primary_position ?? secondary.primary_position ?? null,
    clubs_preview: clubs.slice(0, 4),
    popularity_score: Math.max(primary.popularity_score, secondary.popularity_score),
    is_cell_relevant: primary.is_cell_relevant || secondary.is_cell_relevant,
  }
}

function dedupePlayersByIdentity(players: EnrichedPlayer[]): EnrichedPlayer[] {
  const best = new Map<string, EnrichedPlayer>()
  for (const player of players) {
    const key = dedupeKeyForPlayer(player)
    const existing = best.get(key)
    if (!existing) {
      best.set(key, player)
    } else {
      best.set(key, mergeEnrichedPlayers(existing, player))
    }
  }
  return [...best.values()]
}

async function fillMissingPlayerMetadata(
  supabase: ReturnType<typeof createClient>,
  players: RawPlayer[],
): Promise<RawPlayer[]> {
  const needsFill = players.filter((p) => !p.nationality_code || !p.primary_position)
  if (needsFill.length === 0) return players

  const ids = needsFill.map((p) => p.id)
  const { data: identityRows } = await supabase
    .from('players')
    .select('id, identity_key, nationality_code, primary_position')
    .in('id', ids)

  const identityKeys = [
    ...new Set(
      (identityRows ?? [])
        .map((row) => row.identity_key as string | null)
        .filter((key): key is string => Boolean(key)),
    ),
  ]
  if (identityKeys.length === 0) return players

  const { data: siblings } = await supabase
    .from('players')
    .select('identity_key, nationality_code, primary_position')
    .in('identity_key', identityKeys)

  const bestByKey = new Map<string, { nat?: string | null; pos?: string | null }>()
  for (const row of siblings ?? []) {
    const key = row.identity_key as string
    const current = bestByKey.get(key) ?? {}
    if (row.nationality_code && !current.nat) current.nat = row.nationality_code as string
    if (row.primary_position && !current.pos) current.pos = row.primary_position as string
    bestByKey.set(key, current)
  }

  const idToKey = new Map<string, string>()
  for (const row of identityRows ?? []) {
    if (row.identity_key) idToKey.set(row.id as string, row.identity_key as string)
  }

  return players.map((player) => {
    const key = idToKey.get(player.id)
    const fill = key ? bestByKey.get(key) : undefined
    const withIdentity = key ? { ...player, identity_key: player.identity_key ?? key } : player
    if (!fill) return withIdentity
    return {
      ...withIdentity,
      nationality_code: withIdentity.nationality_code ?? fill.nat ?? null,
      primary_position: withIdentity.primary_position ?? fill.pos ?? null,
    }
  })
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
      const filled = await fillMissingPlayerMetadata(supabase, raw)
      const suggested = await enrichPlayers(supabase, filled, rowClubId, colClubId)

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
      const filledPopular = await fillMissingPlayerMetadata(supabase, raw)
      const enrichedPopular = await enrichPlayers(supabase, filledPopular, rowClubId, colClubId)
      const results = dedupePlayersByIdentity(enrichedPopular).slice(0, limit)

      let suggested: EnrichedPlayer[] = []
      if (rowClubId && colClubId) {
        const { data: intersectionRows } = await supabase.rpc('get_intersection_players', {
          p_row_club_id: rowClubId,
          p_col_club_id: colClubId,
        })
        const intersectionRaw = ((intersectionRows ?? []) as RawPlayer[]).slice(0, Math.min(limit, 12))
        const filledIntersection = await fillMissingPlayerMetadata(supabase, intersectionRaw)
        suggested = await enrichPlayers(
          supabase,
          filledIntersection,
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
      .select('id, name, nationality_code, primary_position, identity_key')
      .ilike('normalized_name', `%${normalized}%`)
      .limit(Math.min(limit * 3, 60))

    const filledResults = await fillMissingPlayerMetadata(
      supabase,
      (rawResults ?? []) as RawPlayer[],
    )
    const enriched = await enrichPlayers(
      supabase,
      filledResults,
      rowClubId,
      colClubId,
    )
    const deduped = dedupePlayersByIdentity(enriched)
    const ranked = deduped
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
