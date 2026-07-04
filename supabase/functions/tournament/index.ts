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
    const slug = url.searchParams.get('slug') ?? 'weekly-tournament'
    const limit = Number(url.searchParams.get('limit') ?? 25)
    const userUuid = url.searchParams.get('user_uuid') ?? req.headers.get('x-user-uuid') ?? ''

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: active } = await supabase.rpc('get_active_tournament')
    const tournamentSlug =
      (active as { ok?: boolean; slug?: string })?.ok === true
        ? ((active as { slug?: string }).slug ?? slug)
        : slug

    const { data: leaderboard, error } = await supabase.rpc('get_tournament_leaderboard', {
      p_tournament_slug: tournamentSlug,
      p_limit: limit,
    })

    if (error) {
      return new Response(JSON.stringify({ ok: false, error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    let userRank: number | null = null
    if (userUuid) {
      const { data: row } = await supabase
        .from('tournament_scores')
        .select('best_score')
        .eq('tournament_slug', tournamentSlug)
        .eq('user_uuid', userUuid)
        .maybeSingle()

      if (row) {
        const { count } = await supabase
          .from('tournament_scores')
          .select('*', { count: 'exact', head: true })
          .eq('tournament_slug', tournamentSlug)
          .gt('best_score', row.best_score)
        userRank = (count ?? 0) + 1
      }
    }

    return new Response(
      JSON.stringify({
        ...(active as Record<string, unknown>),
        ...(leaderboard as Record<string, unknown>),
        user_rank: userRank,
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
