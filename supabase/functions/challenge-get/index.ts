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
    const challengeCode = url.searchParams.get('code') ?? (await req.json().catch(() => ({}))).challenge_id

    if (!challengeCode) {
      return new Response(JSON.stringify({ error: 'challenge_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: challenge, error } = await supabase
      .from('challenge_sessions')
      .select(`
        challenge_code, puzzle_id, creator_score, challenger_score,
        status, expires_at,
        puzzles (id, puzzle_date, grid_size, difficulty)
      `)
      .eq('challenge_code', challengeCode)
      .single()

    if (error) throw error

    if (challenge.expires_at && new Date(challenge.expires_at) < new Date()) {
      return new Response(JSON.stringify({ error: 'Challenge expired' }), {
        status: 410,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(
      JSON.stringify({
        challenge_id: challenge.challenge_code,
        puzzle_id: challenge.puzzle_id,
        creator_score: challenge.creator_score,
        challenger_score: challenge.challenger_score,
        status: challenge.status,
        share_url: `crossball://challenge/${challenge.challenge_code}`,
        puzzle: challenge.puzzles,
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
