# CrossBall Supabase Setup

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli)
- Docker (for local development)

## Quick start

```bash
# From project root
cd supabase

# Link to your Supabase project
supabase link --project-ref YOUR_PROJECT_REF

# Apply migrations
supabase db push

# Deploy edge functions
supabase functions deploy daily-puzzle
supabase functions deploy validate-answer
supabase functions deploy search-players
supabase functions deploy challenge-create
supabase functions deploy hint
supabase functions deploy stats
supabase functions deploy sync-user

# Set secrets
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

## Local development

```bash
supabase start
supabase db reset   # applies migrations + seed
supabase functions serve
```

Copy local credentials to `.env`:

```
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=<from supabase status>
```

## Edge functions

| Function | Method | Purpose |
|----------|--------|---------|
| `daily-puzzle` | GET | Today's published puzzle |
| `validate-answer` | POST | Server-side answer validation + rarity |
| `search-players` | GET | Fuzzy player search |
| `hint` | POST | Return hint for cell |
| `challenge-create` | POST | Create async challenge |
| `stats` | GET | User stats aggregate |
| `sync-user` | POST | Upsert anonymous user profile |

See `docs/ARCHITECTURE.md` for request/response contracts.

## RLS notes

- Public read on `clubs`, `players`, published `puzzles`
- Writes go through edge functions with service role
- Client sends `x-user-uuid` header on authenticated requests

## Refresh materialized view

Schedule via pg_cron or run after pipeline ingest:

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY player_club_intersections;
```
