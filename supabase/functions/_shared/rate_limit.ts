type Bucket = { count: number; resetAt: number }

const buckets = new Map<string, Bucket>()

/** Best-effort in-memory rate limit (per edge isolate). */
export function checkRateLimit(
  key: string,
  maxRequests: number,
  windowMs: number,
): { allowed: boolean; retryAfterSec?: number } {
  const now = Date.now()
  const bucket = buckets.get(key)

  if (!bucket || now >= bucket.resetAt) {
    buckets.set(key, { count: 1, resetAt: now + windowMs })
    return { allowed: true }
  }

  if (bucket.count >= maxRequests) {
    return {
      allowed: false,
      retryAfterSec: Math.ceil((bucket.resetAt - now) / 1000),
    }
  }

  bucket.count++
  return { allowed: true }
}

export function rateLimitResponse(
  retryAfterSec: number,
  corsHeaders: Record<string, string>,
): Response {
  return new Response(
    JSON.stringify({ error: 'rate_limited', retry_after_sec: retryAfterSec }),
    {
      status: 429,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
        'Retry-After': String(retryAfterSec),
      },
    },
  )
}

export function rateLimitKey(userUuid: string | null, ip: string, action: string): string {
  const identity = userUuid && userUuid.length > 0 ? userUuid : ip
  return `${action}:${identity}`
}

export function clientIp(req: Request): string {
  return (
    req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ??
    req.headers.get('cf-connecting-ip') ??
    'unknown'
  )
}
