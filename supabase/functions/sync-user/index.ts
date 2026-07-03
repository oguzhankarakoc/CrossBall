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
    const body = await req.json()
    const { user_uuid, onboarding_complete, is_premium, locale, theme_preference } = body

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const upsertPayload: Record<string, unknown> = {
      user_uuid,
      updated_at: new Date().toISOString(),
    }

    if (onboarding_complete !== undefined) upsertPayload.onboarding_complete = onboarding_complete
    if (is_premium !== undefined) upsertPayload.is_premium = is_premium
    if (locale !== undefined) upsertPayload.locale = locale
    if (theme_preference !== undefined) upsertPayload.theme_preference = theme_preference

    const { data, error } = await supabase
      .from('users')
      .upsert(upsertPayload, { onConflict: 'user_uuid' })
      .select('id, user_uuid, locale, theme_preference, is_premium')
      .single()

    if (error) throw error

    await supabase.from('user_stats').upsert(
      { user_id: data.id },
      { onConflict: 'user_id', ignoreDuplicates: true },
    )

    return new Response(
      JSON.stringify({
        user_id: data.id,
        user_uuid: data.user_uuid,
        locale: data.locale,
        theme_preference: data.theme_preference,
        is_premium: data.is_premium ?? false,
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
