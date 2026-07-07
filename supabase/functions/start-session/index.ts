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

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'method_not_allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const body = await req.json()
    const userUuid =
      (body.user_uuid as string | undefined) ??
      req.headers.get('x-user-uuid') ??
      ''
    const puzzleId = String(body.puzzle_id ?? '')
    const mode = String(body.mode ?? 'practice')
    const gridSize = Number(body.grid_size ?? 3)

    if (!userUuid || !UUID_RE.test(puzzleId)) {
      return new Response(JSON.stringify({ error: 'invalid_request' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const rl = checkRateLimit(
      rateLimitKey(userUuid, clientIp(req), 'start-session'),
      30,
      60_000,
    )
    if (!rl.allowed) {
      return rateLimitResponse(rl.retryAfterSec!, corsHeaders)
    }

    if (!['daily', 'practice', 'challenge', 'timeline'].includes(mode)) {
      return new Response(JSON.stringify({ error: 'invalid_mode' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: userRow } = await supabase
      .from('users')
      .select('id')
      .eq('user_uuid', userUuid)
      .maybeSingle()

    let resumed = false
    if (userRow?.id) {
      const { data: existingActive } = await supabase
        .from('puzzle_sessions')
        .select('id')
        .eq('user_id', userRow.id)
        .eq('puzzle_id', puzzleId)
        .eq('mode', mode)
        .eq('status', 'active')
        .maybeSingle()
      resumed = Boolean(existingActive?.id)
    }

    const { data: sessionId, error } = await supabase.rpc('start_puzzle_session', {
      p_user_uuid: userUuid,
      p_puzzle_id: puzzleId,
      p_mode: mode,
      p_grid_size: gridSize,
    })

    if (error) {
      const msg = error.message ?? String(error)
      const status = msg.includes('user_not_found')
        ? 404
        : msg.includes('puzzle_not_found')
          ? 404
          : 500
      return new Response(JSON.stringify({ error: msg }), {
        status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: progress, error: progressError } = await supabase.rpc(
      'get_session_progress',
      {
        p_session_id: sessionId,
        p_user_uuid: userUuid,
      },
    )

    if (progressError || !progress) {
      return new Response(JSON.stringify({ error: progressError?.message ?? 'progress_failed' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const payload = {
      ...(progress as Record<string, unknown>),
      session_id: sessionId,
      resumed,
      ok: true,
    }

    return new Response(JSON.stringify(payload), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
