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
      challenge_id,
      user_uuid,
      session_id,
      challenger_score,
      mistakes = 0,
      hints_used = 0,
      duration_ms = 0,
    } = await req.json()

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: user } = await supabase
      .from('users')
      .select('id')
      .eq('user_uuid', user_uuid)
      .single()

    const { data: challenge, error: fetchError } = await supabase
      .from('challenge_sessions')
      .select('id, creator_user_id, creator_score, challenger_score, status')
      .eq('challenge_code', challenge_id)
      .single()

    if (fetchError) throw fetchError

    const adjustedScore =
      Number(challenger_score) -
      mistakes * 10 -
      hints_used * 5 -
      (duration_ms / 60000) * 0.5

    let winnerUserId: string | null = null
    if (adjustedScore > Number(challenge.creator_score)) {
      winnerUserId = user?.id ?? null
    } else if (adjustedScore < Number(challenge.creator_score)) {
      winnerUserId = challenge.creator_user_id
    }

    const { data: updated, error } = await supabase
      .from('challenge_sessions')
      .update({
        challenger_user_id: user?.id,
        challenger_session_id: session_id,
        challenger_score: adjustedScore,
        winner_user_id: winnerUserId,
        status: 'completed',
      })
      .eq('challenge_code', challenge_id)
      .select('challenge_code, creator_score, challenger_score, winner_user_id, status')
      .single()

    if (error) throw error

    return new Response(
      JSON.stringify({
        challenge_id: updated.challenge_code,
        creator_score: updated.creator_score,
        challenger_score: updated.challenger_score,
        winner_user_id: updated.winner_user_id,
        status: updated.status,
        you_won: winnerUserId === user?.id,
        is_tie: winnerUserId === null,
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
