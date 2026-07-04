import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

const PUZZLE_SELECT = `
  id, puzzle_date, grid_size, difficulty, difficulty_tier, puzzle_hash,
  quality_score, human_simulation_score,
  puzzle_row_clubs (row_index, clubs (id, name, slug, country_code, logo_url, display_name, short_name, short_code, league_name, badge_primary_color, badge_secondary_color, badge_accent_color, badge_initials, badge_icon_type, badge_gradient_style)),
  puzzle_col_clubs (col_index, clubs (id, name, slug, country_code, logo_url, display_name, short_name, short_code, league_name, badge_primary_color, badge_secondary_color, badge_accent_color, badge_initials, badge_icon_type, badge_gradient_style)),
  puzzle_cells (id, row_index, col_index, valid_answer_count, difficulty)
`

function formatPuzzleResponse(puzzle: Record<string, unknown>) {
  const rowClubs = ((puzzle.puzzle_row_clubs as Array<{ row_index: number; clubs: unknown }>) ?? [])
    .sort((a, b) => a.row_index - b.row_index)
    .map((r) => r.clubs)

  const colClubs = ((puzzle.puzzle_col_clubs as Array<{ col_index: number; clubs: unknown }>) ?? [])
    .sort((a, b) => a.col_index - b.col_index)
    .map((c) => c.clubs)

  return {
    puzzle_id: puzzle.id,
    date: puzzle.puzzle_date ?? new Date().toISOString().split('T')[0],
    grid_size: puzzle.grid_size,
    difficulty: puzzle.difficulty,
    difficulty_tier: puzzle.difficulty_tier,
    puzzle_hash: puzzle.puzzle_hash,
    quality_score: puzzle.quality_score,
    human_simulation_score: puzzle.human_simulation_score,
    row_clubs: rowClubs,
    col_clubs: colClubs,
    cells: puzzle.puzzle_cells,
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const userUuid = req.headers.get('x-user-uuid') ?? url.searchParams.get('user_uuid') ?? 'anonymous'
    const gridSize = parseInt(url.searchParams.get('grid_size') ?? '3', 10)
    const tier = url.searchParams.get('difficulty_tier') ?? 'medium'
    const excludeRaw = url.searchParams.get('exclude_puzzle_id')
    const excludePuzzleId =
      excludeRaw && /^[0-9a-f-]{36}$/i.test(excludeRaw) ? excludeRaw : null

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    if (userUuid !== 'anonymous') {
      const { error: quotaError } = await supabase.rpc('assert_practice_can_start', {
        p_user_uuid: userUuid,
      })
      if (quotaError) {
        const msg = quotaError.message ?? String(quotaError)
        const status = msg.includes('practice_ad_required')
          ? 403
          : msg.includes('practice_daily_limit')
            ? 429
            : 500
        return new Response(JSON.stringify({ error: msg }), {
          status,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      await supabase.rpc('consume_practice_ad_unlock', { p_user_uuid: userUuid })
    }

    const { data: puzzleId, error: selectError } = await supabase.rpc('select_practice_puzzle', {
      p_user_uuid: userUuid,
      p_grid_size: gridSize,
      p_difficulty_tier: tier,
      p_lookback_days: 30,
      p_exclude_puzzle_id: excludePuzzleId,
    })

    if (selectError) throw selectError

    const { data: puzzle, error } = await supabase
      .from('puzzles')
      .select(PUZZLE_SELECT)
      .eq('id', puzzleId)
      .single()

    if (error) throw error

    return new Response(JSON.stringify(formatPuzzleResponse(puzzle as Record<string, unknown>)), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    const message =
      err && typeof err === 'object' && 'message' in err
        ? String((err as { message: string }).message)
        : err instanceof Error
          ? err.message
          : JSON.stringify(err)
    console.error('practice-puzzle error:', message)
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
