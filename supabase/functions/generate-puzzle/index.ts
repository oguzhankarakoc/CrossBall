import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

async function puzzleMeta(supabase: ReturnType<typeof createClient>, puzzleId: string) {
  const { data } = await supabase
    .from('puzzles')
    .select('id, quality_score, human_simulation_score, puzzle_hash, difficulty_tier')
    .eq('id', puzzleId)
    .maybeSingle()
  return data
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json().catch(() => ({}))
    const mode = (body.mode as string) ?? 'daily'
    const gridSize = parseInt(String(body.grid_size ?? '3'), 10)
    const tier = (body.difficulty_tier as string) ?? 'medium'
    const puzzleDate = body.puzzle_date as string | undefined
    const maxAttempts = parseInt(String(body.max_attempts ?? '5000'), 10)

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    if (mode === 'daily') {
      const { data: puzzleId, error } = await supabase.rpc('ensure_daily_puzzle', {
        p_date: puzzleDate ?? new Date().toISOString().split('T')[0],
        p_difficulty_tier: tier,
      })
      if (error) throw error
      const meta = await puzzleMeta(supabase, puzzleId as string)
      return new Response(
        JSON.stringify({ puzzle_id: puzzleId, mode: 'daily', ...meta }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const { data: puzzleId, error } = await supabase.rpc('generate_puzzle', {
      p_mode: mode,
      p_grid_size: gridSize,
      p_difficulty_tier: tier,
      p_puzzle_date: puzzleDate ?? null,
      p_max_attempts: maxAttempts,
    })

    if (error) throw error

    const meta = await puzzleMeta(supabase, puzzleId as string)
    return new Response(
      JSON.stringify({ puzzle_id: puzzleId, mode, ...meta }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
