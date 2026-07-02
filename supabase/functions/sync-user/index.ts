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
    const { user_uuid, onboarding_complete, is_premium } = await req.json()

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data, error } = await supabase
      .from('users')
      .upsert(
        {
          user_uuid,
          onboarding_complete: onboarding_complete ?? false,
          is_premium: is_premium ?? false,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_uuid' },
      )
      .select('id, user_uuid')
      .single()

    if (error) throw error

    // Ensure stats row exists
    await supabase.from('user_stats').upsert(
      { user_id: data.id },
      { onConflict: 'user_id', ignoreDuplicates: true },
    )

    return new Response(
      JSON.stringify({ user_id: data.id, user_uuid: data.user_uuid }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
