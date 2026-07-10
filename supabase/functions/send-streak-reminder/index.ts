/**
 * Server-side streak reminder dispatcher (FCM HTTP v1).
 * Requires FCM_SERVICE_ACCOUNT_JSON and registered tokens in user_push_tokens.
 * Invoke via cron: users with push_opt_in, streak > 0, no daily completion today.
 */
import { createClient } from 'npm:@supabase/supabase-js@2'
import {
  parseServiceAccount,
  sendFcmNotification,
  type FcmServiceAccount,
} from '../_shared/fcm_v1.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

type UserRow = {
  user_uuid: string
  user_stats: { current_streak: number } | { current_streak: number }[] | null
}

function currentStreak(row: UserRow): number {
  const stats = row.user_stats
  if (!stats) return 0
  if (Array.isArray(stats)) return Number(stats[0]?.current_streak ?? 0)
  return Number(stats.current_streak ?? 0)
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const cronSecret = Deno.env.get('CRON_SECRET')
  const authHeader = req.headers.get('authorization') ?? ''
  if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const serviceAccountRaw = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')
  if (!serviceAccountRaw) {
    return new Response(
      JSON.stringify({ ok: false, reason: 'fcm_not_configured', sent: 0 }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  let serviceAccount: FcmServiceAccount
  try {
    serviceAccount = parseServiceAccount(serviceAccountRaw)
  } catch {
    return new Response(
      JSON.stringify({ ok: false, reason: 'invalid_service_account', sent: 0 }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: users, error } = await supabase
      .from('users')
      .select('user_uuid, user_stats(current_streak)')
      .eq('push_opt_in', true)

    if (error) throw error

    let sent = 0
    let failed = 0
    for (const user of (users ?? []) as UserRow[]) {
      if (currentStreak(user) <= 0) continue

      const userUuid = user.user_uuid
      const { data: completedToday } = await supabase.rpc('user_completed_daily_today', {
        p_user_uuid: userUuid,
      })
      if (completedToday) continue

      const { data: tokens } = await supabase
        .from('user_push_tokens')
        .select('token, platform')
        .eq('user_uuid', userUuid)
        .eq('is_active', true)

      for (const row of tokens ?? []) {
        const token = row.token as string
        const result = await sendFcmNotification(serviceAccount, token, {
          title: 'Keep your streak!',
          body: 'Your daily CrossBall puzzle is waiting.',
          data: { route: '/puzzle?mode=daily' },
        })
        if (result.ok) sent++
        else failed++
      }
    }

    return new Response(JSON.stringify({ ok: true, sent, failed }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
