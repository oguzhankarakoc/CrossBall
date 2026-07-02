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

  const start = performance.now()

  try {
    const url = new URL(req.url)
    const query = url.searchParams.get('q')?.trim() ?? ''
    const limit = Math.min(parseInt(url.searchParams.get('limit') ?? '20'), 50)

    if (query.length < 1) {
      const supabase = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      )

      const { data: popular } = await supabase
        .from('player_popularity')
        .select('players (id, name, nationality_code, primary_position)')
        .order('global_selection_count', { ascending: false })
        .limit(limit)

      const results = (popular ?? []).map((p: { players: Record<string, unknown> }) => p.players)

      return new Response(
        JSON.stringify({ results, latency_ms: Math.round(performance.now() - start) }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const normalized = query
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: results } = await supabase
      .from('players')
      .select('id, name, nationality_code, primary_position')
      .ilike('normalized_name', `%${normalized}%`)
      .limit(limit)

    const latency = Math.round(performance.now() - start)

    return new Response(
      JSON.stringify({ results: results ?? [], latency_ms: latency }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
