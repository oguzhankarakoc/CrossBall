import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

const ROLLOUT_WINDOW_MS = 3 * 60 * 60 * 1000

type RolloutStatus = {
  puzzle_date?: string
  status?: string
  started_at?: string | null
  completed_at?: string | null
  elapsed_seconds?: number
  error_message?: string | null
  retry_after?: number
  puzzle_id?: string
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

function formatError(err: unknown): string {
  if (err == null) return 'unknown_error'
  if (typeof err === 'string') return err
  if (typeof err === 'object') {
    const e = err as Record<string, unknown>
    const parts = [e.message, e.details, e.hint, e.code]
      .filter((p) => typeof p === 'string' && p.length > 0)
      .map(String)
    if (parts.length > 0) return parts.join(' — ')
    try {
      return JSON.stringify(err)
    } catch {
      return String(err)
    }
  }
  return String(err)
}

function utcMidnightMs(dateStr: string): number {
  return Date.parse(`${dateStr}T00:00:00.000Z`)
}

function isWithinRolloutWindow(today: string): boolean {
  const elapsed = Date.now() - utcMidnightMs(today)
  return elapsed >= 0 && elapsed < ROLLOUT_WINDOW_MS
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function fetchExistingDailyId(
  supabase: ReturnType<typeof createClient>,
  today: string,
): Promise<string | null> {
  const { data, error } = await supabase
    .from('puzzles')
    .select('id')
    .eq('puzzle_date', today)
    .eq('mode', 'daily')
    .eq('grid_size', 3)
    .eq('is_published', true)
    .maybeSingle()

  if (error) throw error
  return (data?.id as string | undefined) ?? null
}

async function getRolloutStatus(
  supabase: ReturnType<typeof createClient>,
  today: string,
): Promise<RolloutStatus> {
  const { data, error } = await supabase.rpc('get_daily_puzzle_rollout', { p_date: today })
  if (error) throw error
  return (data ?? {}) as RolloutStatus
}

async function peekRolloutStatus(
  supabase: ReturnType<typeof createClient>,
  today: string,
): Promise<RolloutStatus> {
  const { data, error } = await supabase.rpc('peek_daily_puzzle_rollout', { p_date: today })
  if (error) throw error
  return (data ?? {}) as RolloutStatus
}

function inProgressPayload(rollout: RolloutStatus, today: string) {
  return {
    code: 'generation_in_progress',
    error: 'Daily puzzle refresh in progress',
    puzzle_date: today,
    status: rollout.status ?? 'generating',
    started_at: rollout.started_at ?? null,
    elapsed_seconds: rollout.elapsed_seconds ?? 0,
    retry_after: rollout.retry_after ?? 30,
  }
}

function failedPayload(rollout: RolloutStatus, today: string, detail?: string) {
  return {
    code: 'generation_failed',
    error: detail ?? rollout.error_message ?? 'Daily puzzle generation failed',
    puzzle_date: today,
    status: 'failed',
    started_at: rollout.started_at ?? null,
    elapsed_seconds: rollout.elapsed_seconds ?? 0,
    retry_after: rollout.retry_after ?? 60,
  }
}

async function markRolloutComplete(
  supabase: ReturnType<typeof createClient>,
  today: string,
  puzzleId: string,
  source = 'edge',
): Promise<void> {
  const { error } = await supabase.rpc('complete_daily_puzzle_rollout', {
    p_date: today,
    p_puzzle_id: puzzleId,
    p_source: source,
  })
  if (error) console.warn('complete_daily_puzzle_rollout:', formatError(error))
}

async function markRolloutFailed(
  supabase: ReturnType<typeof createClient>,
  today: string,
  message: string,
  source = 'edge',
): Promise<void> {
  const { error } = await supabase.rpc('fail_daily_puzzle_rollout', {
    p_date: today,
    p_error_message: message,
    p_source: source,
  })
  if (error) console.warn('fail_daily_puzzle_rollout:', formatError(error))
}

async function emergencyEnsureDaily(
  supabase: ReturnType<typeof createClient>,
  today: string,
  preferredTier: string,
): Promise<string> {
  const tiers = [...new Set([preferredTier, 'medium', 'easy', 'hard', 'legend'])]
  let lastError: unknown = null

  for (const tier of tiers) {
    const { data, error } = await supabase.rpc('ensure_daily_puzzle', {
      p_date: today,
      p_difficulty_tier: tier,
    })
    if (!error && data) {
      await markRolloutComplete(supabase, today, data as string, 'edge_emergency')
      return data as string
    }
    lastError = error ?? lastError
  }

  const retryExisting = await fetchExistingDailyId(supabase, today)
  if (retryExisting) {
    await markRolloutComplete(supabase, today, retryExisting, 'edge_emergency')
    return retryExisting
  }

  const { data: graphPairs, error: graphError } = await supabase.rpc(
    'ensure_club_relationship_graph',
    { p_min_pairs: 100 },
  )
  if (graphError) {
    console.warn('ensure_club_relationship_graph:', formatError(graphError))
  } else {
    console.log('club_relationships pairs:', graphPairs)
  }

  for (const minAnswers of [3, 1]) {
    const { data, error } = await supabase.rpc('generate_daily_puzzle_fast', {
      p_puzzle_date: today,
      p_grid_size: 3,
      p_min_answers: minAnswers,
      p_max_attempts: minAnswers === 3 ? 200 : 300,
    })
    if (!error && data) {
      await markRolloutComplete(supabase, today, data as string, 'edge_fast')
      return data as string
    }
    lastError = error ?? lastError
  }

  const finalExisting = await fetchExistingDailyId(supabase, today)
  if (finalExisting) {
    await markRolloutComplete(supabase, today, finalExisting, 'edge_emergency')
    return finalExisting
  }

  throw lastError ?? new Error('ensure_daily_puzzle failed for all tiers')
}

function shouldBlockGeneration(rollout: RolloutStatus, today: string): boolean {
  if (rollout.status === 'generating') return true
  if (rollout.status === 'pending' && isWithinRolloutWindow(today)) return true
  return false
}

function shouldAttemptEmergency(rollout: RolloutStatus, today: string): boolean {
  if (rollout.status === 'failed') return true
  if (rollout.status === 'generating' && !isWithinRolloutWindow(today)) return true
  if ((rollout.status === 'pending' || rollout.status == null) && !isWithinRolloutWindow(today)) {
    return true
  }
  return false
}

async function resolveDailyPuzzleId(
  supabase: ReturnType<typeof createClient>,
  today: string,
  preferredTier: string,
): Promise<{ puzzleId: string } | { blocked: RolloutStatus } | { failed: RolloutStatus; detail?: string }> {
  const existingId = await fetchExistingDailyId(supabase, today)
  if (existingId) {
    await markRolloutComplete(supabase, today, existingId)
    return { puzzleId: existingId }
  }

  const rollout = await getRolloutStatus(supabase, today)

  if (rollout.status === 'ready' && rollout.puzzle_id) {
    return { puzzleId: rollout.puzzle_id }
  }

  if (shouldBlockGeneration(rollout, today)) {
    return { blocked: rollout }
  }

  if (shouldAttemptEmergency(rollout, today)) {
    try {
      const puzzleId = await emergencyEnsureDaily(supabase, today, preferredTier)
      return { puzzleId }
    } catch (err) {
      const detail = formatError(err)
      await markRolloutFailed(supabase, today, detail, 'edge_emergency')
      const failedRollout = await getRolloutStatus(supabase, today)
      return { failed: failedRollout, detail }
    }
  }

  if (isWithinRolloutWindow(today)) {
    return { blocked: rollout }
  }

  try {
    const puzzleId = await emergencyEnsureDaily(supabase, today, preferredTier)
    return { puzzleId }
  } catch (err) {
    const detail = formatError(err)
    await markRolloutFailed(supabase, today, detail, 'edge_emergency')
    const failedRollout = await getRolloutStatus(supabase, today)
    return { failed: failedRollout, detail }
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const userUuid =
      url.searchParams.get('user_uuid') ?? req.headers.get('x-user-uuid') ?? ''
    const statusOnly = url.searchParams.get('status_only') === 'true'

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const today = new Date().toISOString().split('T')[0]

    const existingId = await fetchExistingDailyId(supabase, today)

    if (statusOnly) {
      if (existingId) {
        return jsonResponse({
          puzzle_date: today,
          status: 'ready',
          puzzle_id: existingId,
          retry_after: 0,
        })
      }
      const rollout = await peekRolloutStatus(supabase, today)
      if (shouldBlockGeneration(rollout, today)) {
        return jsonResponse(inProgressPayload(rollout, today), 503)
      }
      if (rollout.status === 'failed') {
        return jsonResponse(failedPayload(rollout, today), 503)
      }
      return jsonResponse({
        puzzle_date: today,
        status: rollout.status ?? 'pending',
        started_at: rollout.started_at ?? null,
        elapsed_seconds: rollout.elapsed_seconds ?? 0,
        retry_after: rollout.retry_after ?? 30,
        error_message: rollout.error_message ?? null,
      })
    }

    if (existingId) {
      await markRolloutComplete(supabase, today, existingId)
      const { data: puzzle, error } = await supabase
        .from('puzzles')
        .select(PUZZLE_SELECT)
        .eq('id', existingId)
        .single()
      if (error) throw error
      return jsonResponse(formatPuzzleResponse(puzzle as Record<String, unknown>))
    }

    let difficultyTier = 'medium'
    if (userUuid) {
      const { data: profile } = await supabase.rpc('gee_get_profile', {
        p_user_uuid: userUuid,
      })
      const gamesPlayed =
        profile && typeof profile === 'object'
          ? (profile as { games_played?: number }).games_played ?? 0
          : 0
      if (gamesPlayed < 7) {
        difficultyTier = 'easy'
      } else if (gamesPlayed >= 30) {
        difficultyTier = 'hard'
      }
    }

    const resolved = await resolveDailyPuzzleId(supabase, today, difficultyTier)

    if ('blocked' in resolved) {
      return jsonResponse(inProgressPayload(resolved.blocked, today), 503)
    }

    if ('failed' in resolved) {
      return jsonResponse(failedPayload(resolved.failed, today, resolved.detail), 503)
    }

    const { data: puzzle, error } = await supabase
      .from('puzzles')
      .select(PUZZLE_SELECT)
      .eq('id', resolved.puzzleId)
      .single()

    if (error) throw error

    return jsonResponse(formatPuzzleResponse(puzzle as Record<string, unknown>))
  } catch (err) {
    const message = formatError(err)
    console.error('daily-puzzle error:', message, err)
    return jsonResponse({ code: 'internal_error', error: message }, 500)
  }
})
