import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

function formatPuzzleResponse(puzzle: Record<string, unknown>) {
  const rowClubs = ((puzzle.puzzle_row_clubs as Array<{ row_index: number; clubs: unknown }>) ?? [])
    .sort((a, b) => a.row_index - b.row_index)
    .map((r) => r.clubs)

  const colClubs = ((puzzle.puzzle_col_clubs as Array<{ col_index: number; clubs: unknown }>) ?? [])
    .sort((a, b) => a.col_index - b.col_index)
    .map((c) => c.clubs)

  return {
    puzzle_id: puzzle.id,
    date: puzzle.puzzle_date,
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

const PUZZLE_SELECT = `
  id, puzzle_date, grid_size, difficulty, difficulty_tier, puzzle_hash,
  quality_score, human_simulation_score,
  puzzle_row_clubs (row_index, clubs (id, name, slug, country_code, logo_url, display_name, short_name, short_code, league_name, badge_primary_color, badge_secondary_color, badge_accent_color, badge_initials, badge_icon_type, badge_gradient_style)),
  puzzle_col_clubs (col_index, clubs (id, name, slug, country_code, logo_url, display_name, short_name, short_code, league_name, badge_primary_color, badge_secondary_color, badge_accent_color, badge_initials, badge_icon_type, badge_gradient_style)),
  puzzle_cells (id, row_index, col_index, valid_answer_count, difficulty)
`

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const userUuid =
      url.searchParams.get('user_uuid') ?? req.headers.get('x-user-uuid') ?? ''

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const today = new Date().toISOString().split('T')[0]

    let difficultyTier = 'hard'
    if (userUuid) {
      const { data: profile } = await supabase.rpc('gee_get_profile', {
        p_user_uuid: userUuid,
      })
      const gamesPlayed =
        profile && typeof profile === 'object'
          ? (profile as { games_played?: number }).games_played ?? 0
          : 0
      if (gamesPlayed < 7) difficultyTier = 'easy'
    }

    const { data: puzzleId, error: ensureError } = await supabase.rpc('ensure_daily_puzzle', {
      p_date: today,
      p_difficulty_tier: difficultyTier,
    })

    if (ensureError) throw ensureError

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
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
