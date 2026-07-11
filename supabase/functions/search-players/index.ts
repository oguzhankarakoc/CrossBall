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
  obscurity_score?: number | null
}

type EnrichedPlayer = RawPlayer & {
  clubs_preview: string[]
  popularity_score: number
  obscurity_score: number
  is_cell_relevant: boolean
  /** Internal: identity sibling validates for current cell (even in competitive). */
  validates_cell?: boolean
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

function playerIdentityKeys(name: string, dbIdentityKey?: string | null): string[] {
  const keys = new Set<string>()
  if (dbIdentityKey) keys.add(dbIdentityKey)
  const normalized = normalizeQuery(prepareNameForIdentity(name))
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
  const parts = normalized.split(/\s+/).filter(Boolean)
  if (parts.length === 0) return [...keys]
  const first = parts[0].replace(/\.$/, '')
  const token = first.charAt(0)
  for (const part of parts) {
    if (SURNAME_PARTICLES.has(part)) continue
    keys.add(`${part}|${token}`)
  }
  return [...keys]
}

function dedupeKeysForPlayer(player: EnrichedPlayer): string[] {
  return playerIdentityKeys(player.name, player.identity_key)
}

function playerCompletenessScore(player: EnrichedPlayer): number {
  let score = (player.clubs_preview?.length ?? 0) * 5
  if (player.nationality_code) score += 20
  if (player.primary_position) score += 10
  score += player.name.length
  if (!/^[A-Z]\.\s/.test(player.name)) score += 15
  return score
}

function clubLabelTokens(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim()
}

function clubLabelsMatch(a: string, b: string): boolean {
  const left = clubLabelTokens(a)
  const right = clubLabelTokens(b)
  if (!left || !right) return false
  if (left === right) return true
  if (left.includes(right) || right.includes(left)) return true
  if (right.length <= 4) {
    return left.split(' ').some((part) => part.startsWith(right))
  }
  if (left.length <= 4) {
    return right.split(' ').some((part) => part.startsWith(left))
  }
  return false
}

/** Put puzzle axis clubs first so long careers still show the relevant pair. */
function prioritizeCellClubs(clubs: string[], preferredLabels: string[]): string[] {
  if (clubs.length === 0 || preferredLabels.length === 0) return clubs
  const matched: string[] = []
  const used = new Set<string>()
  for (const preferred of preferredLabels) {
    const hit = clubs.find((club) => !used.has(club) && clubLabelsMatch(club, preferred))
    if (hit) {
      matched.push(hit)
      used.add(hit)
    }
  }
  const rest = clubs.filter((club) => !used.has(club))
  return [...matched, ...rest]
}

async function fetchClubPreviewLabels(
  supabase: ReturnType<typeof createClient>,
  clubId: string | null | undefined,
): Promise<string[]> {
  if (!clubId) return []
  const { data } = await supabase
    .from('clubs')
    .select('short_name, name, short_code')
    .eq('id', clubId)
    .maybeSingle()
  if (!data) return []
  return [data.short_name, data.short_code, data.name]
    .map((v) => (typeof v === 'string' ? v.trim() : ''))
    .filter((v) => v.length > 0)
}

function mergeEnrichedPlayers(
  a: EnrichedPlayer,
  b: EnrichedPlayer,
  intersectionIds?: Set<string>,
): EnrichedPlayer {
  const scoreA = playerCompletenessScore(a)
  const scoreB = playerCompletenessScore(b)
  const aValid = a.validates_cell === true || intersectionIds?.has(a.id) === true
  const bValid = b.validates_cell === true || intersectionIds?.has(b.id) === true

  // Prefer an id that validate_player_intersection would accept for this cell.
  let primary: EnrichedPlayer
  let secondary: EnrichedPlayer
  if (aValid !== bValid) {
    primary = aValid ? a : b
    secondary = aValid ? b : a
  } else if (scoreA !== scoreB) {
    primary = scoreA >= scoreB ? a : b
    secondary = primary === a ? b : a
  } else {
    primary = a
    secondary = b
  }

  const clubs = [...new Set([...(primary.clubs_preview ?? []), ...(secondary.clubs_preview ?? [])])]
  return {
    ...primary,
    identity_key: primary.identity_key ?? secondary.identity_key ?? null,
    nationality_code: primary.nationality_code ?? secondary.nationality_code ?? null,
    primary_position: primary.primary_position ?? secondary.primary_position ?? null,
    clubs_preview: clubs.slice(0, 8),
    popularity_score: Math.max(primary.popularity_score, secondary.popularity_score),
    obscurity_score: Math.max(primary.obscurity_score ?? 50, secondary.obscurity_score ?? 50),
    is_cell_relevant: primary.is_cell_relevant || secondary.is_cell_relevant,
    validates_cell: aValid || bValid || primary.validates_cell === true || secondary.validates_cell === true,
  }
}

function dedupePlayersByIdentity(
  players: EnrichedPlayer[],
  intersectionIds?: Set<string>,
): EnrichedPlayer[] {
  if (players.length <= 1) return players

  const parent = players.map((_, i) => i)
  const find = (i: number): number => {
    while (parent[i] !== i) {
      parent[i] = parent[parent[i]]
      i = parent[i]
    }
    return i
  }
  const union = (a: number, b: number) => {
    const rootA = find(a)
    const rootB = find(b)
    if (rootA !== rootB) parent[rootB] = rootA
  }

  const keyToIndex = new Map<string, number>()
  for (let i = 0; i < players.length; i++) {
    for (const key of dedupeKeysForPlayer(players[i])) {
      const existing = keyToIndex.get(key)
      if (existing === undefined) {
        keyToIndex.set(key, i)
      } else {
        union(i, existing)
      }
    }
  }

  const groups = new Map<number, EnrichedPlayer[]>()
  for (let i = 0; i < players.length; i++) {
    const root = find(i)
    const list = groups.get(root) ?? []
    list.push(players[i])
    groups.set(root, list)
  }

  return [...groups.values()].map((group) => {
    group.sort((a, b) => playerCompletenessScore(b) - playerCompletenessScore(a))
    return group
      .slice(1)
      .reduce(
        (acc, cur) => mergeEnrichedPlayers(acc, cur, intersectionIds),
        group[0],
      )
  })
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
  // Prefer intersection-valid + obscure picks over global popularity.
  let score = (player.obscurity_score ?? 50) * 3 - player.popularity_score * 2

  if (player.is_cell_relevant) score += 400
  if (!normalized) return score

  if (name === normalized) score += 1000
  else if (name.startsWith(normalized)) score += 500
  else if (name.includes(normalized)) score += 200

  return score
}

async function resolveIdentitySiblingMap(
  supabase: ReturnType<typeof createClient>,
  playerIds: string[],
): Promise<Map<string, string[]>> {
  const map = new Map<string, string[]>()
  if (playerIds.length === 0) return map

  const { data: rows } = await supabase
    .from('players')
    .select('id, identity_key')
    .in('id', playerIds)

  const keys = new Set<string>()
  const idToKey = new Map<string, string>()
  for (const row of rows ?? []) {
    const id = row.id as string
    const key = (row.identity_key as string | null)?.trim()
    if (key) {
      keys.add(key)
      idToKey.set(id, key)
    }
  }

  const siblingsByKey = new Map<string, string[]>()
  if (keys.size > 0) {
    const { data: siblings } = await supabase
      .from('players')
      .select('id, identity_key')
      .in('identity_key', [...keys])

    for (const row of siblings ?? []) {
      const key = (row.identity_key as string | null)?.trim()
      const id = row.id as string
      if (!key) continue
      const list = siblingsByKey.get(key) ?? []
      list.push(id)
      siblingsByKey.set(key, list)
    }
  }

  for (const id of playerIds) {
    const key = idToKey.get(id)
    map.set(id, key ? (siblingsByKey.get(key) ?? [id]) : [id])
  }
  return map
}

async function enrichPlayers(
  supabase: ReturnType<typeof createClient>,
  players: RawPlayer[],
  rowClubId?: string | null,
  colClubId?: string | null,
  options?: { markCellRelevant?: boolean; cellClubLabels?: string[] },
): Promise<EnrichedPlayer[]> {
  if (players.length === 0) return []

  const markCellRelevant = options?.markCellRelevant === true
  const cellClubLabels = options?.cellClubLabels ?? []

  const ids = players.map((p) => p.id)
  const siblingMap = await resolveIdentitySiblingMap(supabase, ids)
  const expandedIds = [...new Set([...siblingMap.values()].flat())]

  // Always resolve intersection when cell clubs are known so dedupe can
  // prefer a player_id that validate_player_intersection accepts (fixes
  // "green ticks but Wrong" when name-deduped duplicates lack identity_key).
  // is_cell_relevant badge still only set when markCellRelevant (non-competitive).
  const [{ data: careers }, { data: popularity }, intersectionIds] = await Promise.all([
    supabase
      .from('player_career_history')
      .select('player_id, appearances, clubs (short_name, name, is_top_club)')
      .in('player_id', expandedIds)
      .eq('is_senior', true)
      .eq('is_youth', false)
      .eq('is_reserve', false),
    supabase
      .from('player_popularity')
      .select('player_id, global_selection_count')
      .in('player_id', expandedIds),
    rowClubId && colClubId
      ? fetchIntersectionIds(supabase, expandedIds, rowClubId, colClubId)
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

  return players.map((player) => {
    const siblingIds = siblingMap.get(player.id) ?? [player.id]
    const mergedClubs: string[] = []
    let popularityScore = 0
    let obscurityScore = Number(player.obscurity_score ?? 50)
    for (const siblingId of siblingIds) {
      for (const club of clubsByPlayer.get(siblingId) ?? []) {
        if (!mergedClubs.includes(club)) mergedClubs.push(club)
      }
      popularityScore = Math.max(popularityScore, popByPlayer.get(siblingId) ?? 0)
    }

    // Prefer submitting an identity sibling that actually validates for the cell.
    const validatesCell = siblingIds.some((siblingId) => intersectionIds.has(siblingId))
    const validatingSibling =
      siblingIds.find((siblingId) => intersectionIds.has(siblingId)) ?? player.id
    const isCellRelevant = markCellRelevant && validatesCell

    return {
      ...player,
      id: validatingSibling,
      clubs_preview: prioritizeCellClubs(mergedClubs, cellClubLabels).slice(0, 4),
      popularity_score: popularityScore,
      obscurity_score: obscurityScore,
      is_cell_relevant: isCellRelevant,
      validates_cell: validatesCell,
    }
  })
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

  // Materialized view may be stale; verify candidates via RPC (identity-aware on DB).
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
    const competitive = url.searchParams.get('competitive') === '1'
    // Competitive search may still send club ids for preview ordering, but must not
    // mark is_cell_relevant (would spoil answers via ranking / bolt badge).
    const markCellRelevant = Boolean(rowClubId && colClubId && !competitive)

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const [rowLabels, colLabels] = await Promise.all([
      fetchClubPreviewLabels(supabase, rowClubId),
      fetchClubPreviewLabels(supabase, colClubId),
    ])
    const cellClubLabels = [...rowLabels, ...colLabels]
    const enrichOpts = { markCellRelevant, cellClubLabels }

    const withPrioritizedClubs = (players: EnrichedPlayer[]): EnrichedPlayer[] =>
      players.map((player) => ({
        ...player,
        clubs_preview: prioritizeCellClubs(player.clubs_preview ?? [], cellClubLabels).slice(
          0,
          4,
        ),
      }))

    if (mode === 'suggested' && rowClubId && colClubId) {
      const { data: intersectionRows } = await supabase.rpc('get_intersection_players', {
        p_row_club_id: rowClubId,
        p_col_club_id: colClubId,
      })

      const raw = ((intersectionRows ?? []) as RawPlayer[]).slice(0, limit)
      const filled = await fillMissingPlayerMetadata(supabase, raw)
      const suggested = withPrioritizedClubs(
        await enrichPlayers(supabase, filled, rowClubId, colClubId, {
          markCellRelevant: true,
          cellClubLabels,
        }),
      )

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
      const enrichedPopular = await enrichPlayers(
        supabase,
        filledPopular,
        rowClubId,
        colClubId,
        enrichOpts,
      )
      const results = withPrioritizedClubs(
        dedupePlayersByIdentity(enrichedPopular),
      ).slice(0, limit)

      let suggested: EnrichedPlayer[] = []
      if (rowClubId && colClubId) {
        const { data: intersectionRows } = await supabase.rpc('get_intersection_players', {
          p_row_club_id: rowClubId,
          p_col_club_id: colClubId,
        })
        const intersectionRaw = ((intersectionRows ?? []) as RawPlayer[]).slice(0, Math.min(limit, 12))
        const filledIntersection = await fillMissingPlayerMetadata(supabase, intersectionRaw)
        suggested = withPrioritizedClubs(
          await enrichPlayers(supabase, filledIntersection, rowClubId, colClubId, {
            markCellRelevant: true,
            cellClubLabels,
          }),
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
      .select('id, name, nationality_code, primary_position, identity_key, obscurity_score')
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
      enrichOpts,
    )
    const deduped = withPrioritizedClubs(dedupePlayersByIdentity(enriched))
    const ranked = deduped
      .sort((a, b) => scorePlayer(b, normalized) - scorePlayer(a, normalized))
      .slice(0, limit)
      .map(({ validates_cell: _v, ...rest }) => rest)

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
