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
      mistakes = 0,
      hints_used = 0,
      total_duration_ms = 0,
      background_duration_ms = 0,
      inactive_periods = 0,
      is_suspicious = false,
      user_uuid,
      mode = 'practice',
      difficulty_tier = 'medium',
      puzzle_quality_score = 85,
      challenge_won,
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

    const { data: sessionRow, error: sessionFetchError } = await supabase
      .from('puzzle_sessions')
      .select('id, user_id, puzzle_id, mode, status, final_score, is_suspicious')
      .eq('id', session_id)
      .maybeSingle()

    if (sessionFetchError || !sessionRow) {
      return new Response(JSON.stringify({ error: 'session_not_found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: userRow } = await supabase
      .from('users')
      .select('id')
      .eq('user_uuid', user_uuid)
      .maybeSingle()

    if (!userRow || userRow.id !== sessionRow.user_id) {
      return new Response(JSON.stringify({ error: 'session_forbidden' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (sessionRow.status === 'completed') {
      return new Response(
        JSON.stringify({
          ok: true,
          already_completed: true,
          session_id,
          final_score: sessionRow.final_score,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    if (sessionRow.status !== 'active') {
      return new Response(JSON.stringify({ error: 'session_not_active' }), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const sessionMode = sessionRow.mode ?? mode

    if (sessionMode === 'daily') {
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

    const { data: scoreMetrics, error: scoreError } = await supabase.rpc(
      'compute_session_score',
      { p_session_id: session_id },
    )

    if (scoreError) {
      console.error('compute_session_score failed:', scoreError.message)
    }

    const metrics = (scoreMetrics ?? {}) as Record<string, unknown>
    const serverHints = Number(metrics.hints_used ?? hints_used)
    const finalScore = Number(metrics.final_score ?? 0)
    const correctCount = Number(metrics.correct_count ?? 0)
    const rareCount = Number(metrics.rare_count ?? 0)
    const legendaryCount = Number(metrics.legendary_count ?? 0)
    const mythicCount = Number(metrics.mythic_count ?? 0)
    const isPerfect =
      Boolean(metrics.is_perfect) && Number(mistakes) === 0 && serverHints === 0

    const suspicious = Boolean(is_suspicious)
    const status = suspicious ? 'suspicious' : 'completed'

    await supabase
      .from('puzzle_sessions')
      .update({
        final_score: finalScore,
        mistakes,
        hints_used: serverHints,
        total_duration_ms,
        background_duration_ms,
        inactive_periods,
        is_suspicious: suspicious,
        status,
        completed_at: new Date().toISOString(),
      })
      .eq('id', session_id)
      .eq('status', 'active')

    let economyResult: Record<string, unknown> | null = null

    if (!suspicious) {
      const eventType =
        sessionMode === 'daily'
          ? 'daily_completed'
          : sessionMode === 'practice'
            ? 'practice_completed'
            : sessionMode === 'timeline'
              ? 'timeline_completed'
              : 'puzzle_completed'

      const payload = {
        final_score: finalScore,
        mistakes,
        hints_used: serverHints,
        total_duration_ms,
        mode: sessionMode,
        difficulty_tier,
        puzzle_quality_score,
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

      if (sessionMode === 'challenge' && typeof challenge_won === 'boolean') {
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
          total_mistakes: (stats?.total_mistakes ?? 0) + Number(mistakes),
          hints_used: (stats?.hints_used ?? 0) + serverHints,
          current_streak: Number(economyResult?.current_streak ?? stats?.current_streak ?? 0),
          best_streak: Number(economyResult?.best_streak ?? stats?.best_streak ?? 0),
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id' },
      )

      await supabase.rpc('log_player_activity', {
        p_user_uuid: user_uuid,
        p_event_type: `${sessionMode}_completed`,
        p_payload: {
          final_score: finalScore,
          mode: sessionMode,
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
        if (slug && ['daily', 'practice', 'timeline'].includes(String(sessionMode))) {
          await supabase.rpc('upsert_tournament_score', {
            p_tournament_slug: slug,
            p_user_uuid: user_uuid,
            p_score: finalScore,
          })
        }
      }
    }

    let practiceQuota: Record<string, unknown> | null = null
    if (user_uuid && (sessionMode === 'practice' || sessionMode === 'timeline') && !suspicious) {
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
