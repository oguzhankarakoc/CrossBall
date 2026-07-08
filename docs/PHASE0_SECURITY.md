# Phase 0 — Security Hardening

Server-authoritative sessions, premium lockdown, RPC grant revocation, and authoritative scoring.

## Deploy

```bash
# 1. Migration
./scripts/run_migrations.sh 021

# 2. Edge function secrets (Supabase dashboard → Edge Functions → Secrets)
#    IAP_SKIP_VERIFY=true          # staging only
#    IAP_PREMIUM_PRODUCT_ID=crossball_premium

# 3. Deploy updated + new functions
supabase functions deploy sync-user validate-answer complete-session request-hint
supabase functions deploy start-session verify-premium
supabase functions deploy practice-puzzle practice-quota register-push-token
```

## What changed

| Area | Before | After |
|------|--------|-------|
| Premium | Client sends `is_premium` via sync-user | Only `verify-premium` (IAP receipt) sets premium |
| Economy RPCs | Callable with anon key | Service role only (edge functions) |
| Sessions | Client-generated UUID | `start-session` creates DB row |
| Answers | Not persisted | Stored in `answers` on validate-answer |
| Score | Client-reported | Computed from `answers` + `session_hints` |
| complete-session | Replayable | Idempotent; daily duplicate blocked |
| Hints | UI-only premium gate | Server checks session + premium for career_club |

## Client requirements

- Hot restart after pull
- Supabase must be configured (demo offline mode still uses local UUID sessions)
- Premium demo (`IAP_ENABLED=false`): calls `verify-premium` with `platform=dev` (requires `IAP_SKIP_VERIFY=true` on server)

## Production checklist (remaining)

- [ ] Set `IAP_SKIP_VERIFY=false` in production
- [ ] Wire Apple App Store / Google Play receipt validation in `verify-premium`
- [ ] Set `IAP_STRICT_VERIFY=true` when validation is live
- [ ] Add rate limiting (Cloudflare / Supabase gateway)
- [ ] Optional: Supabase Anonymous Auth JWT for `user_uuid` binding

## Migration 036 — PostgREST lockdown

After migration `021`, economy and session RPCs were service-role only. Migration **`036_security_rls_lockdown.sql`** extends this to the entire schema:

- RLS enabled (and forced where needed) on all public tables
- Legacy public-read policies removed
- No table or RPC grants for `anon` / `authenticated`

Clients must use Edge Functions only. See [`supabase/SECURITY.md`](../supabase/SECURITY.md).

```bash
./scripts/run_migrations.sh 036
# or: supabase db push
```

## Breaking changes

- Direct PostgREST calls to `gee_process_event` will fail (intentional)
- Calling `grant_practice_ad_unlock` with anon key will fail (use practice-quota edge)
- Old clients without `start-session` will fail validate-answer (session_not_found)
