import { createClient } from 'npm:@supabase/supabase-js@2'

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
      final_score,
      mistakes = 0,
      hints_used = 0,
      total_duration_ms = 0,
      is_suspicious = false,
      user_uuid,
      mode = 'practice',
      difficulty_tier = 'medium',
      puzzle_quality_score = 85,
      is_perfect = false,
      rare_count = 0,
      legendary_count = 0,
      mythic_count = 0,
      correct_count = 0,
      challenge_won,
    } = body

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    let userId: string | null = null
    if (user_uuid) {
      const { data: user } = await supabase
        .from('users')
        .select('id')
        .eq('user_uuid', user_uuid)
        .single()
      userId = user?.id ?? null
    }

    await supabase.from('puzzle_sessions').upsert(
      {
        id: session_id,
        user_id: userId,
        final_score,
        mistakes,
        hints_used,
        total_duration_ms,
        is_suspicious,
        status: is_suspicious ? 'suspicious' : 'completed',
        completed_at: new Date().toISOString(),
      },
      { onConflict: 'id' },
    )

    let economyResult: Record<string, unknown> | null = null

    if (user_uuid && !is_suspicious) {
      const eventType =
        mode === 'daily'
          ? 'daily_completed'
          : mode === 'practice'
            ? 'practice_completed'
            : 'puzzle_completed'

      const payload = {
        final_score,
        mistakes,
        hints_used,
        total_duration_ms,
        mode,
        difficulty_tier,
        puzzle_quality_score,
        is_perfect,
        rare_count,
        legendary_count,
        mythic_count,
        correct_count,
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

      if (mode === 'challenge' && typeof challenge_won === 'boolean') {
        const challengeEvent = challenge_won ? 'challenge_won' : 'challenge_lost'
        const { data: challengeEconomy, error: challengeError } = await supabase.rpc(
          'gee_process_event',
          {
            p_user_uuid: user_uuid,
            p_event_type: challengeEvent,
            p_payload: { final_score, mode: 'challenge' },
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
        .select('games_played, total_score, total_mistakes, hints_used')
        .eq('user_id', userId)
        .maybeSingle()

      await supabase.from('user_stats').upsert(
        {
          user_id: userId,
          games_played: (stats?.games_played ?? 0) + 1,
          total_score: Number(stats?.total_score ?? 0) + Number(final_score),
          total_mistakes: (stats?.total_mistakes ?? 0) + mistakes,
          hints_used: (stats?.hints_used ?? 0) + hints_used,
          current_streak: Number(economyResult?.current_streak ?? stats?.current_streak ?? 0),
          best_streak: Number(economyResult?.best_streak ?? stats?.best_streak ?? 0),
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id' },
      )
    }

    return new Response(
      JSON.stringify({
        ok: true,
        session_id,
        economy: economyResult,
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
