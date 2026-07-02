import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

function generateCode(): string {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
  let code = ''
  for (let i = 0; i < 8; i++) {
    code += chars[Math.floor(Math.random() * chars.length)]
  }
  return code
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { puzzle_id, creator_score, session_id, user_uuid } = await req.json()
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: user } = await supabase
      .from('users')
      .select('id')
      .eq('user_uuid', user_uuid)
      .single()

    const challengeCode = generateCode()

    const { data: challenge, error } = await supabase
      .from('challenge_sessions')
      .insert({
        challenge_code: challengeCode,
        puzzle_id,
        creator_user_id: user?.id,
        creator_session_id: session_id,
        creator_score,
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
      })
      .select('challenge_code')
      .single()

    if (error) throw error

    return new Response(
      JSON.stringify({
        challenge_id: challenge.challenge_code,
        share_url: `crossball://challenge/${challenge.challenge_code}`,
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
