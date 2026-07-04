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

    if (!userUuid) {
      return new Response(JSON.stringify({ ok: false, reason: 'missing_user_uuid' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: profile, error } = await supabase.rpc('gee_get_profile', {
      p_user_uuid: userUuid,
    })

    if (error) {
      return new Response(JSON.stringify({ ok: false, error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: leagues } = await supabase
      .from('economy_leagues')
      .select('slug, label, min_rating, max_rating, badge_color, sort_order')
      .eq('is_active', true)
      .order('sort_order')

    const { data: levelInfo } = await supabase
      .from('economy_level_thresholds')
      .select('level, xp_required_total, title')
      .order('level')

    return new Response(
      JSON.stringify({
        ...(profile as Record<string, unknown>),
        leagues: leagues ?? [],
        level_curve: levelInfo ?? [],
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
