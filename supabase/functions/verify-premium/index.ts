import { createClient } from 'npm:@supabase/supabase-js@2'
import { createHash } from 'node:crypto'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'method_not_allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const body = await req.json()
    const userUuid =
      (body.user_uuid as string | undefined) ??
      req.headers.get('x-user-uuid') ??
      ''
    const platform = String(body.platform ?? '').toLowerCase()
    const productId = String(body.product_id ?? '')
    const verificationData = String(body.verification_data ?? '')

    if (!userUuid || !productId) {
      return new Response(JSON.stringify({ error: 'missing_fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const expectedProduct = Deno.env.get('IAP_PREMIUM_PRODUCT_ID') ?? 'crossball_premium'
    if (productId !== expectedProduct) {
      return new Response(JSON.stringify({ error: 'invalid_product' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const skipVerify = Deno.env.get('IAP_SKIP_VERIFY') === 'true'
    const devSecret = Deno.env.get('IAP_DEV_SECRET') ?? ''

    let verified = false
    let verifyPlatform = platform

    if (skipVerify && platform === 'dev') {
      verified = true
      verifyPlatform = 'dev'
    } else if (verificationData.length > 0) {
      // Phase 0: persist receipt / transaction id for manual / future automated validation.
      const strictVerify = Deno.env.get('IAP_STRICT_VERIFY') === 'true'
      if (strictVerify) {
        return new Response(JSON.stringify({ error: 'receipt_validation_not_configured' }), {
          status: 501,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
      verified = true
    } else if (devSecret && body.dev_secret === devSecret) {
      verified = true
      verifyPlatform = 'dev'
    }

    if (!verified) {
      return new Response(JSON.stringify({ error: 'verification_failed' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const hash = verificationData
      ? createHash('sha256').update(verificationData).digest('hex').slice(0, 32)
      : null

    await supabase.from('iap_verifications').insert({
      user_uuid: userUuid,
      platform: verifyPlatform || platform || 'unknown',
      product_id: productId,
      verification_hash: hash,
    })

    const { error: premiumError } = await supabase.rpc('set_user_premium', {
      p_user_uuid: userUuid,
      p_is_premium: true,
      p_premium_until: null,
    })

    if (premiumError) throw premiumError

    return new Response(
      JSON.stringify({ ok: true, is_premium: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    const message =
      err && typeof err === 'object' && 'message' in err
        ? String((err as { message: string }).message)
        : String(err)
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
