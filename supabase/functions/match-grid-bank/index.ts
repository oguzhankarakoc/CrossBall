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

type CellInput = {
  row: number
  col: number
  row_club_id: string
  col_club_id: string
}

type CellPool = CellInput & { candidates: PlayerRow[] }

/**
 * Exact-cover style assignment:
 * 1) Always fill the scarcest remaining cell first.
 * 2) Prefer players who fit the fewest remaining cells (unique chips first).
 *
 * Prevents multi-club stars (e.g. Coutinho) from randomly locking a
 * secondary intersection while their obvious cell still needs a chip.
 */
function assignPlacements(pools: CellPool[]): Array<{
  row: number
  col: number
  player: PlayerRow
}> | null {
  const remaining = pools.map((p) => ({
    row: p.row,
    col: p.col,
    candidates: [...p.candidates],
  }))
  const usedIds = new Set<string>()
  const placements: Array<{ row: number; col: number; player: PlayerRow }> = []

  while (remaining.length > 0) {
    // Refresh candidate lists against used ids, then pick scarcest cell.
    for (const cell of remaining) {
      cell.candidates = cell.candidates.filter((c) => c?.id && !usedIds.has(c.id))
    }
    remaining.sort((a, b) => a.candidates.length - b.candidates.length)

    const cell = remaining[0]
    if (!cell || cell.candidates.length === 0) {
      return null
    }

    // How many remaining cells each candidate still fits.
    const fitCount = new Map<string, number>()
    for (const other of remaining) {
      for (const c of other.candidates) {
        if (!c?.id) continue
        fitCount.set(c.id, (fitCount.get(c.id) ?? 0) + 1)
      }
    }

    const minFits = Math.min(
      ...cell.candidates.map((c) => fitCount.get(c.id) ?? 99),
    )
    const preferred = cell.candidates.filter(
      (c) => (fitCount.get(c.id) ?? 99) === minFits,
    )
    const pick = shuffle(preferred)[0]
    if (!pick?.id) return null

    usedIds.add(pick.id)
    placements.push({
      row: cell.row,
      col: cell.col,
      player: {
        id: pick.id,
        name: pick.name,
        nationality_code: pick.nationality_code ?? null,
        primary_position: pick.primary_position ?? null,
      },
    })
    remaining.shift()
  }

  return placements
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ ok: false, reason: 'method_not_allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const body = await req.json()
    const cells = (body?.cells ?? []) as CellInput[]
    if (!Array.isArray(cells) || cells.length === 0 || cells.length > 16) {
      return new Response(JSON.stringify({ ok: false, reason: 'invalid_cells' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    for (const cell of cells) {
      if (
        typeof cell.row !== 'number' ||
        typeof cell.col !== 'number' ||
        !UUID_RE.test(cell.row_club_id ?? '') ||
        !UUID_RE.test(cell.col_club_id ?? '')
      ) {
        return new Response(JSON.stringify({ ok: false, reason: 'invalid_cell' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const pools: CellPool[] = []
    for (const cell of cells) {
      const { data: correctRows, error } = await supabase.rpc('get_intersection_players', {
        p_row_club_id: cell.row_club_id,
        p_col_club_id: cell.col_club_id,
      })
      if (error) {
        return new Response(JSON.stringify({ ok: false, error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      const candidates = ((correctRows ?? []) as PlayerRow[]).filter((p) => !!p?.id)
      if (candidates.length === 0) {
        return new Response(
          JSON.stringify({
            ok: false,
            reason: 'no_correct_players',
            row: cell.row,
            col: cell.col,
          }),
          {
            status: 404,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          },
        )
      }

      pools.push({
        ...cell,
        candidates: shuffle(candidates),
      })
    }

    const placements = assignPlacements(pools)
    if (!placements) {
      return new Response(
        JSON.stringify({ ok: false, reason: 'exact_cover_failed' }),
        {
          status: 409,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      )
    }

    const tray = shuffle(placements.map((p) => p.player))

    return new Response(
      JSON.stringify({
        ok: true,
        placements,
        tray,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    return new Response(JSON.stringify({ ok: false, error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
