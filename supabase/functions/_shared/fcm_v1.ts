import { SignJWT, importPKCS8 } from 'npm:jose@5'

export type FcmServiceAccount = {
  project_id: string
  client_email: string
  private_key: string
}

export function parseServiceAccount(raw: string): FcmServiceAccount {
  const sa = JSON.parse(raw) as FcmServiceAccount
  if (!sa.project_id || !sa.client_email || !sa.private_key) {
    throw new Error('invalid_service_account')
  }
  return sa
}

let tokenCache: { token: string; expiresAtMs: number } | null = null

export async function getFcmAccessToken(sa: FcmServiceAccount): Promise<string> {
  const now = Date.now()
  if (tokenCache && tokenCache.expiresAtMs > now + 60_000) {
    return tokenCache.token
  }

  const key = await importPKCS8(sa.private_key, 'RS256')
  const iat = Math.floor(now / 1000)
  const jwt = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(iat)
    .setExpirationTime(iat + 3600)
    .sign(key)

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  if (!res.ok) {
    const text = await res.text()
    throw new Error(`fcm_token_error: ${res.status} ${text}`)
  }

  const body = (await res.json()) as { access_token: string; expires_in: number }
  tokenCache = {
    token: body.access_token,
    expiresAtMs: now + body.expires_in * 1000,
  }
  return body.access_token
}

export async function sendFcmNotification(
  sa: FcmServiceAccount,
  deviceToken: string,
  payload: {
    title: string
    body: string
    data?: Record<string, string>
  },
): Promise<{ ok: boolean; status: number; error?: string }> {
  const accessToken = await getFcmAccessToken(sa)
  const url =
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token: deviceToken,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data ?? {},
        apns: {
          headers: {
            'apns-priority': '10',
            'apns-push-type': 'alert',
          },
          payload: {
            aps: {
              alert: {
                title: payload.title,
                body: payload.body,
              },
              sound: 'default',
            },
          },
        },
      },
    }),
  })

  if (res.ok) return { ok: true, status: res.status }

  const text = await res.text()
  return { ok: false, status: res.status, error: text }
}
