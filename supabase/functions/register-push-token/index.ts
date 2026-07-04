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
    const token = (body.token as string | undefined)?.trim() ?? ''
    const platform = (body.platform as string | undefined)?.trim().toLowerCase() ?? ''

    if (!userUuid || !token || !platform) {
      return new Response(JSON.stringify({ error: 'missing_fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!['ios', 'android', 'web'].includes(platform)) {
      return new Response(JSON.stringify({ error: 'invalid_platform' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: tokenId, error } = await supabase.rpc('upsert_push_token', {
      p_user_uuid: userUuid,
      p_token: token,
      p_platform: platform,
      p_app_version: body.app_version ?? null,
      p_locale: body.locale ?? null,
    })

    if (error) throw error

    if (body.push_opt_in !== undefined) {
      await supabase
        .from('users')
        .update({ push_opt_in: Boolean(body.push_opt_in), updated_at: new Date().toISOString() })
        .eq('user_uuid', userUuid)
    }

    return new Response(JSON.stringify({ ok: true, token_id: tokenId }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
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
