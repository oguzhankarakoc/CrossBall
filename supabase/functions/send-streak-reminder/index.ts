/**
 * Server-side streak reminder dispatcher.
 * Requires FCM server key (FCM_SERVER_KEY) and registered tokens in user_push_tokens.
 * Invoke via cron: users with push_opt_in, streak > 0, no daily completion today.
 */
import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
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

  const fcmKey = Deno.env.get('FCM_SERVER_KEY')
  if (!fcmKey) {
    return new Response(
      JSON.stringify({ ok: false, reason: 'fcm_not_configured', sent: 0 }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: users, error } = await supabase
      .from('users')
      .select('user_uuid, push_opt_in')
      .eq('push_opt_in', true)

    if (error) throw error

    let sent = 0
    for (const user of users ?? []) {
      const userUuid = user.user_uuid as string
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
        const res = await fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            Authorization: `key=${fcmKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            to: token,
            notification: {
              title: 'Keep your streak!',
              body: 'Your daily CrossBall puzzle is waiting.',
            },
            data: { route: '/puzzle?mode=daily' },
          }),
        })
        if (res.ok) sent++
      }
    }

    return new Response(JSON.stringify({ ok: true, sent }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
