import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

/** Slugs that refer to the same logical club (legacy seed vs ETL). */
const SLUG_ALIAS_GROUPS: string[][] = [
  ['barcelona', 'fc-barcelona'],
  ['chelsea', 'chelsea-fc'],
  ['psg', 'paris-saintgermain', 'paris-saint-germain'],
]

function canonicalSlug(slug: string): string {
  for (const group of SLUG_ALIAS_GROUPS) {
    if (group.includes(slug)) return group[0]
  }
  return slug
}

function tierFromUsage(pct: number): string {
  if (pct > 50) return 'common'
  if (pct > 25) return 'rare'
  if (pct > 10) return 'epic'
  if (pct > 3) return 'legendary'
  return 'mythic'
}

async function resolveEquivalentClubIds(
  supabase: ReturnType<typeof createClient>,
  clubRef: string,
): Promise<string[]> {
  const { data: rpcIds, error } = await supabase.rpc('club_ids_equivalent_to', {
    p_club_ref: clubRef,
  })
  if (!error && Array.isArray(rpcIds) && rpcIds.length > 0) {
    return rpcIds as string[]
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

  const canonical = canonicalSlug(slug)
  const aliasSlugs = SLUG_ALIAS_GROUPS.find((g) => g[0] === canonical) ?? [slug]

  const { data: clubs } = await supabase.from('clubs').select('id, slug').in('slug', aliasSlugs)

  const ids = new Set<string>()
  if (UUID_RE.test(clubRef)) ids.add(clubRef)
  for (const club of clubs ?? []) ids.add(club.id as string)
  return [...ids]
}

async function playerPlayedForClubRef(
  supabase: ReturnType<typeof createClient>,
  playerId: string,
  clubRef: string,
): Promise<boolean> {
  const clubIds = await resolveEquivalentClubIds(supabase, clubRef)
  if (clubIds.length === 0) return false

  const { count } = await supabase
    .from('player_career_history')
    .select('*', { count: 'exact', head: true })
    .eq('player_id', playerId)
    .eq('is_senior', true)
    .eq('is_youth', false)
    .eq('is_reserve', false)
    .in('club_id', clubIds)

  return (count ?? 0) > 0
}

Deno.serve(async (req) => {
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

    const [hasRow, hasCol] = await Promise.all([
      playerPlayedForClubRef(supabase, player_id, String(row_club_id)),
      playerPlayedForClubRef(supabase, player_id, String(col_club_id)),
    ])
    const correct = hasRow && hasCol

    let usagePercentage = 0
    let rarityScore = 0
    const validCellId = puzzle_cell_id && UUID_RE.test(String(puzzle_cell_id))

    if (correct && validCellId) {
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
