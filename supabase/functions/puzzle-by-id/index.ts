import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const puzzleId = url.searchParams.get('id') ?? (await req.json().catch(() => ({}))).puzzle_id

    if (!puzzleId) {
      return new Response(JSON.stringify({ error: 'puzzle_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: puzzle, error } = await supabase
      .from('puzzles')
      .select(`
        id, puzzle_date, grid_size, difficulty,
        puzzle_row_clubs (row_index, clubs (id, name, slug, country_code, logo_url, display_name, short_name, short_code, league_name, badge_primary_color, badge_secondary_color, badge_accent_color, badge_initials, badge_icon_type, badge_gradient_style)),
        puzzle_col_clubs (col_index, clubs (id, name, slug, country_code, logo_url, display_name, short_name, short_code, league_name, badge_primary_color, badge_secondary_color, badge_accent_color, badge_initials, badge_icon_type, badge_gradient_style)),
        puzzle_cells (id, row_index, col_index, valid_answer_count, difficulty)
      `)
      .eq('id', puzzleId)
      .single()

    if (error) throw error

    const rowClubs = (puzzle.puzzle_row_clubs ?? [])
      .sort((a: { row_index: number }, b: { row_index: number }) => a.row_index - b.row_index)
      .map((r: { clubs: unknown }) => r.clubs)

    const colClubs = (puzzle.puzzle_col_clubs ?? [])
      .sort((a: { col_index: number }, b: { col_index: number }) => a.col_index - b.col_index)
      .map((c: { clubs: unknown }) => c.clubs)

    return new Response(
      JSON.stringify({
        puzzle_id: puzzle.id,
        date: puzzle.puzzle_date,
        grid_size: puzzle.grid_size,
        difficulty: puzzle.difficulty,
        row_clubs: rowClubs,
        col_clubs: colClubs,
        cells: puzzle.puzzle_cells,
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
