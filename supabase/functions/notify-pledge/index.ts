import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface Payload {
  type: 'new_pledge' | 'pledge_confirmed' | 'pledge_rejected'
  pledge_id: string
  recipient: string
}

interface PushToken {
  token: string
  platform: string
}

// ── FCM JWT auth ──────────────────────────────────────────────────────────────

async function getFcmAccessToken(serviceAccount: Record<string, string>): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header = { alg: 'RS256', typ: 'JWT' }
  const claim = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  }

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  const unsigned = `${encode(header)}.${encode(claim)}`

  const pemBody = serviceAccount.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')

  const keyData = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0))
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyData,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(unsigned),
  )

  const sig = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')

  const jwt = `${unsigned}.${sig}`

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  if (!tokenRes.ok) {
    throw new Error(`OAuth token exchange failed: ${await tokenRes.text()}`)
  }

  const { access_token } = await tokenRes.json()
  return access_token as string
}

// ── Send one FCM message ──────────────────────────────────────────────────────

async function sendFcm(
  accessToken: string,
  projectId: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<{ success: boolean; invalidToken: boolean }> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          android: {
            notification: { channel_id: 'needlink_high', priority: 'HIGH' },
            priority: 'HIGH',
          },
        },
      }),
    },
  )

  if (res.ok) return { success: true, invalidToken: false }

  const err = await res.json().catch(() => ({}))
  const status = (err as { error?: { status?: string } })?.error?.status
  const invalidToken = status === 'INVALID_ARGUMENT' || status === 'NOT_FOUND'
  return { success: false, invalidToken }
}

// ── Notification copy ─────────────────────────────────────────────────────────

function buildNotificationCopy(type: Payload['type']): { title: string; body: string } {
  switch (type) {
    case 'new_pledge':
      return { title: 'New Pledge Received', body: 'A donor has pledged items for your need.' }
    case 'pledge_confirmed':
      return { title: 'Pledge Confirmed', body: 'Your pledge has been confirmed by the NGO.' }
    case 'pledge_rejected':
      return { title: 'Pledge Update', body: 'Your pledge could not be accepted. See details in the app.' }
  }
}

// ── Handler ───────────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  let payload: Payload
  try {
    payload = (await req.json()) as Payload
  } catch {
    return new Response('Bad request', { status: 400 })
  }

  const { type, pledge_id, recipient } = payload
  if (!type || !pledge_id || !recipient) {
    return new Response('Missing fields', { status: 400 })
  }

  const serviceAccountRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
  if (!serviceAccountRaw) {
    return new Response('FIREBASE_SERVICE_ACCOUNT not set', { status: 500 })
  }

  const serviceAccount = JSON.parse(serviceAccountRaw) as Record<string, string>
  const projectId = serviceAccount.project_id

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  )

  // Verify pledge exists and recipient is actually associated with it
  const { data: pledge } = await supabase
    .from('pledges')
    .select('id, donor_id, donation_need:donation_needs!inner(ngo_id, ngos!inner(admin_id))')
    .eq('id', pledge_id)
    .maybeSingle()

  if (!pledge) {
    return new Response('Pledge not found', { status: 404 })
  }

  const ngoAdminId = (pledge as any).donation_need?.ngos?.admin_id
  const donorId = (pledge as any).donor_id
  const validRecipients = [donorId, ngoAdminId].filter(Boolean)

  if (!validRecipients.includes(recipient)) {
    return new Response('Recipient mismatch', { status: 403 })
  }

  const { data: tokens, error: tokenErr } = await supabase
    .from('push_tokens')
    .select('token, platform')
    .eq('user_id', recipient)

  if (tokenErr || !tokens || tokens.length === 0) {
    return new Response('No tokens', { status: 200 })
  }

  const accessToken = await getFcmAccessToken(serviceAccount)
  const { title, body } = buildNotificationCopy(type)
  const data = { type, pledge_id }
  const invalidTokens: string[] = []

  await Promise.all(
    (tokens as PushToken[]).map(async ({ token }) => {
      const result = await sendFcm(accessToken, projectId, token, title, body, data)
      if (result.invalidToken) invalidTokens.push(token)
    }),
  )

  if (invalidTokens.length > 0) {
    await supabase.from('push_tokens').delete().in('token', invalidTokens)
  }

  return new Response(JSON.stringify({ sent: tokens.length - invalidTokens.length }), {
    headers: { 'Content-Type': 'application/json' },
    status: 200,
  })
})
