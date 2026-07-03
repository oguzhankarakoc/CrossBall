# CrossBall Supabase Setup

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli)
- Docker (optional, for local development)
- `DATABASE_URL` in `data_pipeline/.env` (for remote migration script)

## Quick start (remote project)

```bash
# From project root
supabase link --project-ref YOUR_PROJECT_REF

# Apply migrations (recommended — uses DATABASE_URL)
./scripts/run_migrations.sh

# Or via Supabase CLI
supabase db push

# Deploy all edge functions
supabase functions deploy daily-puzzle
supabase functions deploy validate-answer
supabase functions deploy search-players
supabase functions deploy puzzle-by-id
supabase functions deploy request-hint
supabase functions deploy complete-session
supabase functions deploy challenge-create
supabase functions deploy challenge-get
supabase functions deploy challenge-complete
supabase functions deploy sync-user
supabase functions deploy stats
```

Edge functions use `npm:@supabase/supabase-js@2` imports (see `supabase/functions/deno.json`). Do **not** use bare `deno.land` imports — deploy will fail.

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

## Migrations

| File | Purpose |
|------|---------|
| `001_initial_schema.sql` | Core tables, RLS, puzzle schema |
| `002_club_badges_and_theme.sql` | Club badge colors and theme seed |
| `003_fix_player_club_intersections.sql` | Intersection materialized view fix |
| `004_club_badges_full_seed.sql` | Full badge metadata seed |
| `005_club_identity_v2.sql` | Icon types, gradient styles |
| `006_club_display_names.sql` | Display names, short names, leagues |
| `007_club_slug_canonical.sql` | Slug aliases, `club_ids_equivalent_to`, validation RPCs |
| `008_seed_daily_puzzle.sql` | Repoint stale club FKs, seed today's daily puzzle |

### Apply migrations manually

```bash
chmod +x scripts/run_migrations.sh
./scripts/run_migrations.sh              # all migrations in order
./scripts/run_migrations.sh 007 008      # specific migrations only
```

Uses `DATABASE_URL` from `data_pipeline/.env`.

**Note:** SQL files are **PostgreSQL**. IDE red squiggles from a T-SQL linter are false positives — see `.vscode/settings.json`.

## Edge functions

| Function | Method | Purpose |
|----------|--------|---------|
| `daily-puzzle` | GET | Today's published puzzle |
| `puzzle-by-id` | GET | Fetch puzzle by UUID |
| `validate-answer` | POST | Server-side answer validation + rarity |
| `search-players` | GET | Fuzzy player search with club preview |
| `request-hint` | POST | Return hint for cell |
| `complete-session` | POST | Finalize puzzle session + score |
| `challenge-create` | POST | Create async challenge |
| `challenge-get` | GET | Fetch challenge puzzle by code |
| `challenge-complete` | POST | Submit challenge result |
| `stats` | GET | User stats aggregate |
| `sync-user` | POST | Upsert anonymous user profile |

See `docs/ARCHITECTURE.md` for request/response contracts.

## Validation (`validate-answer`)

Answer validation checks `player_career_history` for senior, non-youth, non-reserve stints at **both** clubs. Club references are resolved through:

1. RPC `club_ids_equivalent_to(p_club_ref)` — merges legacy slug aliases (e.g. `fc-barcelona` → `barcelona`)
2. Fallback slug alias groups in the edge function

Rarity stats are updated only when `puzzle_cell_id` is a valid UUID.

## RLS notes

- Public read on `clubs`, `players`, published `puzzles`
- Writes go through edge functions with service role
- Client sends `x-user-uuid` header on authenticated requests

## Refresh materialized view

Schedule via pg_cron or run after pipeline ingest:

```sql
SELECT public.refresh_player_club_intersections();
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Valid player marked wrong | Deploy latest `validate-answer`; run migration `007` + `008` |
| `deno.land` deploy error | Use `npm:@supabase/supabase-js@2` (already in repo) |
| Empty daily puzzle | Run `./scripts/run_migrations.sh 008` |
| Stale club UUIDs in app | Full app restart (cache key bumps invalidate old puzzles) |
