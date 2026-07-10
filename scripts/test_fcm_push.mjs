#!/usr/bin/env node
/**
 * Send test FCM push via HTTP v1 (no Deno required).
 * Usage: node scripts/test_fcm_push.mjs <service-account.json> <token> [...]
 */
import { readFileSync } from 'node:fs'
import { createSign } from 'node:crypto'

function b64url(input) {
  return Buffer.from(input).toString('base64url')
}

function signJwt(sa) {
  const now = Math.floor(Date.now() / 1000)
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const claim = b64url(
    JSON.stringify({
      iss: sa.client_email,
      sub: sa.client_email,
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
    }),
  )
  const unsigned = `${header}.${claim}`
  const sign = createSign('RSA-SHA256')
  sign.update(unsigned)
  sign.end()
  const signature = sign.sign(sa.private_key).toString('base64url')
  return `${unsigned}.${signature}`
}

async function getAccessToken(sa) {
  const jwt = signJwt(sa)
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })
  if (!res.ok) throw new Error(`oauth ${res.status}: ${await res.text()}`)
  const body = await res.json()
  return body.access_token
}

async function sendPush(sa, accessToken, deviceToken) {
  const url = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`
  const title = 'CrossBall test'
  const body = 'FCM push test — if you see this, server push works.'
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token: deviceToken,
        notification: { title, body },
        data: { route: '/puzzle?mode=daily' },
        apns: {
          headers: {
            'apns-priority': '10',
            'apns-push-type': 'alert',
          },
          payload: {
            aps: {
              alert: { title, body },
              sound: 'default',
            },
          },
        },
      },
    }),
  })
  const text = await res.text()
  return { ok: res.ok, status: res.status, text }
}

const [saPath, ...tokens] = process.argv.slice(2)
if (!saPath || tokens.length === 0) {
  console.error('Usage: node scripts/test_fcm_push.mjs <service-account.json> <token> [...]')
  process.exit(1)
}

const sa = JSON.parse(readFileSync(saPath, 'utf8'))
const accessToken = await getAccessToken(sa)

for (const token of tokens) {
  const short = `${token.slice(0, 12)}...${token.slice(-8)}`
  const result = await sendPush(sa, accessToken, token)
  if (result.ok) {
    console.log(`OK  ${short}`)
  } else {
    console.log(`FAIL ${short} status=${result.status}`)
    console.log(result.text)
  }
}
