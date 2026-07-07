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

function generateCode(): string {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
  let code = ''
  for (let i = 0; i < 8; i++) {
    code += chars[Math.floor(Math.random() * chars.length)]
  }
  return code
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { puzzle_id, session_id, user_uuid } = await req.json()

    if (!user_uuid || !puzzle_id || !session_id || !UUID_RE.test(String(session_id))) {
      return new Response(JSON.stringify({ error: 'invalid_request' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const rl = checkRateLimit(
      rateLimitKey(user_uuid, clientIp(req), 'challenge-create'),
      10,
      60_000,
    )
    if (!rl.allowed) {
      return rateLimitResponse(rl.retryAfterSec!, corsHeaders)
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

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

    const creatorScore = Number((scoreMetrics as Record<string, unknown>)?.final_score ?? 0)

    const { data: user } = await supabase
      .from('users')
      .select('id')
      .eq('user_uuid', user_uuid)
      .single()

    const challengeCode = generateCode()

    const { data: challenge, error } = await supabase
      .from('challenge_sessions')
      .insert({
        challenge_code: challengeCode,
        puzzle_id,
        creator_user_id: user?.id,
        creator_session_id: session_id,
        creator_score: creatorScore,
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
      })
      .select('challenge_code')
      .single()

    if (error) throw error

    return new Response(
      JSON.stringify({
        challenge_id: challenge.challenge_code,
        puzzle_id,
        creator_score: creatorScore,
        share_url: `crossball://challenge/${challenge.challenge_code}`,
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
