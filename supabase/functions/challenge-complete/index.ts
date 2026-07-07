import { createClient } from 'npm:@supabase/supabase-js@2'
import {
  checkRateLimit,
  clientIp,
  rateLimitKey,
  rateLimitResponse,
} from '../_shared/rate_limit.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const {
      challenge_id,
      user_uuid,
      session_id,
    } = await req.json()

    if (!user_uuid || !challenge_id) {
      return new Response(JSON.stringify({ error: 'invalid_request' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const rl = checkRateLimit(
      rateLimitKey(user_uuid, clientIp(req), 'challenge-complete'),
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

    const { data: user } = await supabase
      .from('users')
      .select('id')
      .eq('user_uuid', user_uuid)
      .single()

    const { data: challenge, error: fetchError } = await supabase
      .from('challenge_sessions')
      .select('id, creator_user_id, creator_score, creator_session_id, challenger_score, status')
      .eq('challenge_code', challenge_id)
      .single()

    if (fetchError) throw fetchError

    let challengerScore = 0
    if (session_id && UUID_RE.test(String(session_id))) {
      const { error: sessionError } = await supabase.rpc('assert_active_session', {
        p_session_id: session_id,
        p_user_uuid: user_uuid,
      })
      if (sessionError) {
        const msg = sessionError.message ?? String(sessionError)
        return new Response(JSON.stringify({ error: msg }), {
          status: msg.includes('forbidden') ? 403 : 409,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      const { data: scoreMetrics, error: scoreError } = await supabase.rpc(
        'compute_session_score',
        { p_session_id: session_id },
      )
      if (scoreError) throw scoreError
      challengerScore = Number((scoreMetrics as Record<string, unknown>)?.final_score ?? 0)
    } else {
      return new Response(JSON.stringify({ error: 'session_id_required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    let creatorScore = Number(challenge.creator_score)
    if (challenge.creator_session_id) {
      const { data: creatorMetrics } = await supabase.rpc('compute_session_score', {
        p_session_id: challenge.creator_session_id,
      })
      if (creatorMetrics) {
        creatorScore = Number((creatorMetrics as Record<string, unknown>).final_score ?? creatorScore)
      }
    }

    let winnerUserId: string | null = null
    if (challengerScore > creatorScore) {
      winnerUserId = user?.id ?? null
    } else if (challengerScore < creatorScore) {
      winnerUserId = challenge.creator_user_id
    }

    const { data: updated, error } = await supabase
      .from('challenge_sessions')
      .update({
        challenger_user_id: user?.id,
        challenger_session_id: session_id,
        challenger_score: challengerScore,
        creator_score: creatorScore,
        winner_user_id: winnerUserId,
        status: 'completed',
      })
      .eq('challenge_code', challenge_id)
      .eq('status', 'open')
      .select('challenge_code, creator_score, challenger_score, winner_user_id, status')
      .maybeSingle()

    if (error) throw error
    if (!updated) {
      return new Response(JSON.stringify({ error: 'challenge_not_open' }), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(
      JSON.stringify({
        challenge_id: updated.challenge_code,
        creator_score: updated.creator_score,
        challenger_score: updated.challenger_score,
        winner_user_id: updated.winner_user_id,
        status: updated.status,
        you_won: winnerUserId === user?.id,
        is_tie: winnerUserId === null,
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
