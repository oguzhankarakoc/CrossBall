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
    const {
      session_id,
      final_score,
      mistakes = 0,
      hints_used = 0,
      total_duration_ms = 0,
      is_suspicious = false,
      user_uuid,
    } = await req.json()

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    let userId: string | null = null
    if (user_uuid) {
      const { data: user } = await supabase
        .from('users')
        .select('id')
        .eq('user_uuid', user_uuid)
        .single()
      userId = user?.id ?? null
    }

    await supabase.from('puzzle_sessions').upsert(
      {
        id: session_id,
        user_id: userId,
        final_score,
        mistakes,
        hints_used,
        total_duration_ms,
        is_suspicious,
        status: is_suspicious ? 'suspicious' : 'completed',
        completed_at: new Date().toISOString(),
      },
      { onConflict: 'id' },
    )

    if (userId && !is_suspicious) {
      const { data: stats } = await supabase
        .from('user_stats')
        .select('games_played, total_score, total_mistakes, hints_used')
        .eq('user_id', userId)
        .maybeSingle()

      await supabase.from('user_stats').upsert(
        {
          user_id: userId,
          games_played: (stats?.games_played ?? 0) + 1,
          total_score: Number(stats?.total_score ?? 0) + Number(final_score),
          total_mistakes: (stats?.total_mistakes ?? 0) + mistakes,
          hints_used: (stats?.hints_used ?? 0) + hints_used,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id' },
      )
    }

    return new Response(
      JSON.stringify({ ok: true, session_id }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
