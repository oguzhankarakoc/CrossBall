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

const NICKNAME_RE = /^[\p{L}\p{N}._-]{3,20}$/u

function normalizeNickname(raw: string): string {
  return raw.trim().replace(/\s+/g, ' ')
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const {
      user_uuid,
      onboarding_complete,
      locale,
      theme_preference,
      display_name,
      timezone_offset_minutes,
      push_opt_in,
    } = body

    if (!user_uuid) {
      return new Response(JSON.stringify({ error: 'missing_user_uuid' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const rl = checkRateLimit(
      rateLimitKey(user_uuid, clientIp(req), 'sync-user'),
      30,
      60_000,
    )
    if (!rl.allowed) {
      return rateLimitResponse(rl.retryAfterSec!, corsHeaders)
    }

    // Premium is set only via verify-premium (IAP receipt), never from client sync.
    if (body.is_premium !== undefined) {
      console.warn('sync-user ignored client is_premium for', user_uuid)
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const upsertPayload: Record<string, unknown> = {
      user_uuid,
      updated_at: new Date().toISOString(),
    }

    if (onboarding_complete !== undefined) upsertPayload.onboarding_complete = onboarding_complete
    if (locale !== undefined) upsertPayload.locale = locale
    if (theme_preference !== undefined) upsertPayload.theme_preference = theme_preference
    if (timezone_offset_minutes !== undefined) {
      upsertPayload.timezone_offset_minutes = Number(timezone_offset_minutes)
    }
    if (push_opt_in !== undefined) upsertPayload.push_opt_in = Boolean(push_opt_in)

    if (display_name !== undefined) {
      const nickname = normalizeNickname(String(display_name))
      if (nickname.length === 0) {
        upsertPayload.display_name = null
      } else if (!NICKNAME_RE.test(nickname)) {
        return new Response(JSON.stringify({ error: 'invalid_display_name' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      } else {
        upsertPayload.display_name = nickname
      }
    }

    const { data, error } = await supabase
      .from('users')
      .upsert(upsertPayload, { onConflict: 'user_uuid' })
      .select(
        'id, user_uuid, display_name, locale, theme_preference, is_premium, premium_until, push_opt_in, timezone_offset_minutes',
      )
      .single()

    if (error) {
      if (error.code === '23505') {
        return new Response(JSON.stringify({ error: 'display_name_taken' }), {
          status: 409,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
      throw error
    }

    await supabase.from('user_stats').upsert(
      { user_id: data.id },
      { onConflict: 'user_id', ignoreDuplicates: true },
    )

    const { data: isPremiumNow } = await supabase.rpc('user_is_premium', {
      p_user_uuid: user_uuid,
    })

    return new Response(
      JSON.stringify({
        user_id: data.id,
        user_uuid: data.user_uuid,
        display_name: data.display_name,
        locale: data.locale,
        theme_preference: data.theme_preference,
        is_premium: isPremiumNow ?? false,
        push_opt_in: data.push_opt_in ?? true,
        timezone_offset_minutes: data.timezone_offset_minutes ?? 0,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    const message =
      err && typeof err === 'object' && 'message' in err
        ? String((err as { message: string }).message)
        : String(err)
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
