# CrossBall Supabase security model

The mobile app **never** reads or writes database tables through the PostgREST API (`/rest/v1`). All client traffic goes through **Edge Functions** using the public anon key; functions use the **service role** server-side.

## What is safe to publish

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` (in `.env.example` only — never commit real `.env`)

The anon key cannot access tables or RPCs after migration `036_security_rls_lockdown.sql`.

## What must stay secret

- `SUPABASE_SERVICE_ROLE_KEY` (Edge Functions / CI only)
- Database password
- Any third-party API secrets

## Database rules

1. **RLS enabled** on every table in `public`.
2. **No permissive policies** for `anon` / `authenticated` on user or session data.
3. **No table or RPC grants** for `anon` / `authenticated`.
4. **Edge Functions** perform authorization (user UUID, session ownership) and use `service_role`.

## Deploying security migrations

```bash
supabase link --project-ref kseqeqpoouneaiymdzpq   # once
supabase db push
```

Then re-run **Security Advisor** in the Supabase dashboard.
