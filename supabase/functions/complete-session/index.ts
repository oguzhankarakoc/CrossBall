import { createClient } from 'npm:@supabase/supabase-js@2'
import {
  checkRateLimit,
  clientIp,
  rateLimitKey,
  rateLimitResponse,
} from '../_shared/rate_limit.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const {
      session_id,
      user_uuid,
      finished_early = false,
      challenge_won,
      mode: bodyMode,
    } = body

    if (!session_id || !user_uuid) {
      return new Response(JSON.stringify({ error: 'missing_fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const rl = checkRateLimit(
      rateLimitKey(user_uuid, clientIp(req), 'complete-session'),
      20,
      60_000,
    )
    if (!rl.allowed) {
      return rateLimitResponse(rl.retryAfterSec!, corsHeaders)
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    if (bodyMode === 'daily') {
      const { data: alreadyDaily } = await supabase.rpc('user_completed_daily_today', {
        p_user_uuid: user_uuid,
      })
      if (alreadyDaily === true) {
        return new Response(JSON.stringify({ error: 'daily_already_completed' }), {
          status: 409,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    const { data: finalized, error: finalizeError } = await supabase.rpc(
      'finalize_puzzle_session',
      {
        p_session_id: session_id,
        p_user_uuid: user_uuid,
        p_finished_early: Boolean(finished_early),
      },
    )

    if (finalizeError) {
      const msg = finalizeError.message ?? String(finalizeError)
      const status = msg.includes('incomplete_session')
        ? 409
        : msg.includes('forbidden')
          ? 403
          : msg.includes('not_found')
            ? 404
            : 500
      return new Response(JSON.stringify({ error: msg }), {
        status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const result = (finalized ?? {}) as Record<string, unknown>

    if (result.already_completed === true) {
      return new Response(
        JSON.stringify({
          ok: true,
          already_completed: true,
          session_id,
          final_score: result.final_score,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const finalScore = Number(result.final_score ?? 0)
    const serverHints = Number(result.hints_used ?? 0)
    const mistakes = Number(result.mistakes ?? 0)
    const correctCount = Number(result.correct_count ?? 0)
    const rareCount = Number(result.rare_count ?? 0)
    const legendaryCount = Number(result.legendary_count ?? 0)
    const mythicCount = Number(result.mythic_count ?? 0)
    const isPerfect = Boolean(result.is_perfect)
    const suspicious = Boolean(result.is_suspicious)
    const totalDurationMs = Number(result.server_duration_ms ?? 0)
    const resolvedMode = String(result.mode ?? bodyMode ?? 'practice')
    const integrity = (result.integrity ?? {}) as Record<string, unknown>
    const expectedCells = Number(integrity.expected_cells ?? 0)
    const fullGrid = expectedCells > 0 && correctCount >= expectedCells

    const { data: userRow } = await supabase
      .from('users')
      .select('id')
      .eq('user_uuid', user_uuid)
      .maybeSingle()

    let puzzleMeta: { difficulty_tier?: string; quality_score?: number } | null = null
    const { data: sessionRow } = await supabase
      .from('puzzle_sessions')
      .select('puzzle_id')
      .eq('id', session_id)
      .maybeSingle()

    if (sessionRow?.puzzle_id) {
      const { data: puzzleRow } = await supabase
        .from('puzzles')
        .select('difficulty_tier, quality_score')
        .eq('id', sessionRow.puzzle_id)
        .maybeSingle()
      puzzleMeta = puzzleRow
    }

    let economyResult: Record<string, unknown> | null = null

    if (!suspicious && userRow?.id) {
      const eventType =
        resolvedMode === 'daily'
          ? 'daily_completed'
          : resolvedMode === 'practice'
            ? 'practice_completed'
            : resolvedMode === 'timeline'
              ? 'timeline_completed'
              : 'puzzle_completed'

      const payload = {
        final_score: finalScore,
        mistakes,
        hints_used: serverHints,
        total_duration_ms: totalDurationMs,
        mode: resolvedMode,
        difficulty_tier: puzzleMeta?.difficulty_tier ?? 'medium',
        puzzle_quality_score: puzzleMeta?.quality_score ?? 85,
        is_perfect: isPerfect,
        rare_count: rareCount,
        legendary_count: legendaryCount,
        mythic_count: mythicCount,
        correct_count: correctCount,
      }

      const { data: puzzleEconomy, error: economyError } = await supabase.rpc(
        'gee_process_event',
        {
          p_user_uuid: user_uuid,
          p_event_type: eventType,
          p_payload: payload,
        },
      )

      if (economyError) {
        console.error('gee_process_event failed:', economyError.message)
      } else {
        economyResult = puzzleEconomy as Record<string, unknown>
      }

      if (resolvedMode === 'challenge' && typeof challenge_won === 'boolean') {
        const challengeEvent = challenge_won ? 'challenge_won' : 'challenge_lost'
        const { data: challengeEconomy, error: challengeError } = await supabase.rpc(
          'gee_process_event',
          {
            p_user_uuid: user_uuid,
            p_event_type: challengeEvent,
            p_payload: { final_score: finalScore, mode: 'challenge' },
          },
        )
        if (!challengeError && challengeEconomy) {
          economyResult = {
            ...(economyResult ?? {}),
            challenge: challengeEconomy,
          }
        }
      }

      const { data: stats } = await supabase
        .from('user_stats')
        .select('games_played, total_score, total_mistakes, hints_used, current_streak, best_streak')
        .eq('user_id', userRow.id)
        .maybeSingle()

      await supabase.from('user_stats').upsert(
        {
          user_id: userRow.id,
          games_played: (stats?.games_played ?? 0) + 1,
          total_score: Number(stats?.total_score ?? 0) + finalScore,
          total_mistakes: (stats?.total_mistakes ?? 0) + mistakes,
          hints_used: (stats?.hints_used ?? 0) + serverHints,
          current_streak: Number(economyResult?.current_streak ?? stats?.current_streak ?? 0),
          best_streak: Number(economyResult?.best_streak ?? stats?.best_streak ?? 0),
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id' },
      )

      await supabase.rpc('log_player_activity', {
        p_user_uuid: user_uuid,
        p_event_type: `${resolvedMode}_completed`,
        p_payload: {
          final_score: finalScore,
          mode: resolvedMode,
          is_perfect: isPerfect,
        },
      })

      const { data: activeTournament } = await supabase.rpc('get_active_tournament')
      if (
        activeTournament &&
        typeof activeTournament === 'object' &&
        (activeTournament as { ok?: boolean }).ok === true
      ) {
        const slug = (activeTournament as { slug?: string }).slug
        if (
          slug &&
          fullGrid &&
          !suspicious &&
          ['daily', 'practice', 'timeline'].includes(resolvedMode)
        ) {
          await supabase.rpc('upsert_tournament_score', {
            p_tournament_slug: slug,
            p_user_uuid: user_uuid,
            p_score: finalScore,
          })
        }
      }
    }

    let practiceQuota: Record<string, unknown> | null = null
    if (
      user_uuid &&
      (resolvedMode === 'practice' || resolvedMode === 'timeline') &&
      !suspicious
    ) {
      const { data: quota, error: quotaError } = await supabase.rpc(
        'consume_practice_session',
        { p_user_uuid: user_uuid },
      )
      if (quotaError) {
        console.error('consume_practice_session failed:', quotaError.message)
      } else {
        practiceQuota = quota as Record<string, unknown>
      }
    }

    return new Response(
      JSON.stringify({
        ok: true,
        session_id,
        final_score: finalScore,
        server_authoritative: true,
        is_suspicious: suspicious,
        economy: economyResult,
        practice_quota: practiceQuota,
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
