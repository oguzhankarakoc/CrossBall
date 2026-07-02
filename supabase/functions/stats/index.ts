import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const userUuid = url.searchParams.get('user_uuid') ?? req.headers.get('x-user-uuid')

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: user } = await supabase
      .from('users')
      .select('id')
      .eq('user_uuid', userUuid)
      .maybeSingle()

    if (!user) {
      return new Response(
        JSON.stringify({
          games_played: 0,
          current_streak: 0,
          best_streak: 0,
          total_score: 0,
          rarity_breakdown: {},
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const { data: stats } = await supabase
      .from('user_stats')
      .select('*')
      .eq('user_id', user.id)
      .maybeSingle()

    return new Response(
      JSON.stringify({
        games_played: stats?.games_played ?? 0,
        current_streak: stats?.current_streak ?? 0,
        best_streak: stats?.best_streak ?? 0,
        total_score: stats?.total_score ?? 0,
        rarity_breakdown: {
          common: stats?.common_count ?? 0,
          rare: stats?.rare_count ?? 0,
          epic: stats?.epic_count ?? 0,
          legendary: stats?.legendary_count ?? 0,
          mythic: stats?.mythic_count ?? 0,
        },
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
