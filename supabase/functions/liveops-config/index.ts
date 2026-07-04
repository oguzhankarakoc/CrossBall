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
    const url = new URL(req.url)
    const userUuid =
      url.searchParams.get('user_uuid') ?? req.headers.get('x-user-uuid')
    const locale = url.searchParams.get('locale') ?? 'en'
    const platform = url.searchParams.get('platform') ?? 'ios'
    const country = url.searchParams.get('country') ?? ''
    const appVersion = url.searchParams.get('app_version') ?? '1.0.0'

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: snapshot, error } = await supabase.rpc('loe_get_snapshot', {
      p_user_uuid: userUuid,
      p_locale: locale,
      p_platform: platform,
      p_country: country,
      p_app_version: appVersion,
    })

    if (error) {
      return new Response(JSON.stringify({ ok: false, error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (userUuid) {
      await supabase.rpc('loe_track_event', {
        p_user_uuid: userUuid,
        p_event_type: 'snapshot_fetched',
        p_payload: { platform, locale, app_version: appVersion },
      })
    }

    return new Response(JSON.stringify(snapshot), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ ok: false, error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
