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
    const userUuid = url.searchParams.get('user_uuid') ?? req.headers.get('x-user-uuid') ?? ''

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: season } = await supabase.rpc('get_active_season')

    let seasonPoints = 0
    if (userUuid) {
      const { data: profile } = await supabase.rpc('gee_get_profile', {
        p_user_uuid: userUuid,
      })
      if (profile && typeof profile === 'object') {
        seasonPoints = (profile as { season_points?: number }).season_points ?? 0
      }
    }

    return new Response(
      JSON.stringify({
        ...(season as Record<string, unknown>),
        season_points: seasonPoints,
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
