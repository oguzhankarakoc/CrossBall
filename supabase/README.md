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
supabase functions deploy economy-profile
supabase functions deploy liveops-config
supabase functions deploy challenge-create
supabase functions deploy challenge-get
supabase functions deploy challenge-complete
supabase functions deploy sync-user
supabase functions deploy practice-puzzle
supabase functions deploy practice-quota
supabase functions deploy register-push-token
supabase functions deploy start-session verify-premium
supabase functions deploy stats grant-hint-ad send-streak-reminder
supabase functions deploy club-mastery season consume-hint-taste
supabase functions deploy activity-feed player-fact tournament career-timeline
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
| `008_seed_daily_puzzle.sql` | Legacy manual seed (superseded by 009 engine) |
| `009_puzzle_generation_engine.sql` | Club relationships, puzzle hash, generation RPCs |
| `010_puzzle_quality_evaluation.sql` | Quality + human simulation scoring gates |
| `011_game_economy_engine.sql` | GEE: progression, config, achievements, missions, seasons |
| `012_liveops_engine.sql` | LOE: remote config, feature flags, events, announcements |
| `013_club_slug_aliases.sql` | Extended slug aliases (bayern-munich, manchester-united, …) |
| `014_puzzle_generation_relationship_aware.sql` | Graph-aware club picking + daily tier fallback |
| `015_puzzle_pick_coordinated.sql` | Optimized pick + relaxed daily quality fallback |
| `016_player_identity_key.sql` | Player dedup identity key |
| `017`–`019` | Practice puzzle selection + fast generation |
| `020_user_identity_practice_quota_push.sql` | Nickname, server practice quota, push token registry |
| `021_security_hardening.sql` | Phase 0: RPC lockdown, server sessions, authoritative scoring |
| `022_phase1_features.sql` | Leaderboard, missions, hint ad tokens, progression RLS |
| `023_phase3_features.sql` | Club mastery, season, career hint taste |
| `024_phase4_features.sql` | Timeline mode, activity feed, facts, tournament |
| `025_club_identity_full_coverage.sql` | Full curated badge symbols for all 105 seed clubs |
| `026_daily_puzzle_resilience.sql` | Sparse club graph refresh + fast fallback generator |
| `027_daily_puzzle_rollout.sql` | Daily puzzle rollout lifecycle (generating/ready/failed) |
| `028_ensure_daily_smallint_cast.sql` | Fix `ensure_daily_puzzle` grid_size SMALLINT cast |
| `029_backfill_player_metadata.sql` | Backfill nationality/position from identity_key siblings |
| `030_fix_ai_features_rollout.sql` | Fix stale LiveOps flag keeping AI features disabled |
| `031_session_resume.sql` | Resume in-progress sessions without duplicates |
| `032_competitive_integrity.sql` | Cell binding, server timing, atomic completion |
| `033_fair_scoring.sql` | Fair daily scoring (base + rarity + completion bonus) |
| `034_merge_ronaldo_identity.sql` | Merge duplicate Cristiano Ronaldo identity rows |
| `035_daily_completion_guard.sql` | Block new daily session after today's completion |
| `036_security_rls_lockdown.sql` | RLS on all tables; revoke anon/authenticated table/RPC access |

Apply through `036` for full feature set + open-source security model. See [`SECURITY.md`](SECURITY.md).

### Phase deploy (021 → 036)

```bash
./scripts/run_migrations.sh 021
./scripts/run_migrations.sh 022
./scripts/run_migrations.sh 023
./scripts/run_migrations.sh 024
./scripts/run_migrations.sh 025
./scripts/run_migrations.sh 036   # RLS lockdown — required for open-source repo
```

Or all at once: `./scripts/run_migrations.sh`

### Apply migrations manually

```bash
chmod +x scripts/run_migrations.sh
./scripts/run_migrations.sh              # all migrations in order
./scripts/run_migrations.sh 007 008      # specific migrations only
```

Uses `DATABASE_URL` from `data_pipeline/.env`. Migrations are **idempotent** — already-applied versions are skipped via `crossball_applied_migrations` (and Supabase CLI tracking when present). Numeric prefixes match both `011` (Supabase CLI) and `011_game_economy_engine` (repo filenames).

```bash
./scripts/run_migrations.sh --sync-tracking   # backfill local tracking from supabase_migrations
./scripts/run_migrations.sh 037 038 039       # apply latest only
```

**Note:** SQL files are **PostgreSQL**. IDE red squiggles from a T-SQL linter are false positives — see `.vscode/settings.json`.

## Edge functions

| Function | Method | Purpose |
|----------|--------|---------|
| `daily-puzzle` | GET | Today's puzzle (auto-generates via engine if missing) |
| `practice-puzzle` | GET | Weighted practice puzzle (quota + ad gate enforced server-side) |
| `practice-quota` | GET/POST | Daily practice quota; POST `grant_ad_unlock` after rewarded ad |
| `register-push-token` | POST | Register FCM/APNs device token (push integration hook) |
| `generate-puzzle` | POST | Manual/cron puzzle generation |
| `puzzle-by-id` | GET | Fetch puzzle by UUID |
| `validate-answer` | POST | Server-side answer validation + rarity |
| `search-players` | GET | Fuzzy player search with club preview |
| `request-hint` | POST | Return hint for cell |
| `complete-session` | POST | Finalize puzzle session + GEE rewards |
| `economy-profile` | GET | Player progression profile (XP, level, rating, league) |
| `liveops-config` | GET | LiveOps snapshot (config, flags, events, announcements) |
| `challenge-create` | POST | Create async challenge |
| `challenge-get` | GET | Fetch challenge puzzle by code |
| `challenge-complete` | POST | Submit challenge result |
| `stats` | GET | User stats aggregate |
| `sync-user` | POST | Upsert anonymous user (nickname, timezone, push opt-in; **not** premium) |
| `verify-premium` | POST | IAP receipt verification → sets premium server-side |
| `start-session` | POST | Create server-authoritative puzzle session |
| `grant-hint-ad` | POST | Consume rewarded-ad token for hint unlock |
| `club-mastery` | GET | Club mastery stats per user |
| `season` | GET | Active season + player season points |
| `consume-hint-taste` | POST | Weekly free career-club hint taste |
| `activity-feed` | GET | Community activity feed |
| `player-fact` | GET | Localized football trivia fact |
| `tournament` | GET | Active tournament leaderboard |
| `career-timeline` | GET | Player career years for timeline mode |
| `send-streak-reminder` | POST | Streak reminder push stub (cron) |

See `docs/ARCHITECTURE.md` for request/response contracts.

## Validation (`validate-answer`)

Answer validation uses RPC `validate_player_intersection` and `club_ids_equivalent_to()` (migration `007` + `013` slug aliases). Example: Real Madrid × Bayern accepts players with senior stints at both clubs (loans count).

Rarity stats are updated only when `puzzle_cell_id` is a valid UUID.

## RLS and client access

The mobile app **does not** read or write PostgreSQL tables via PostgREST. All client traffic goes through **Edge Functions** (anon key → function → service role).

Migration `036_security_rls_lockdown.sql`:
- Enables RLS on every `public` table
- Removes legacy public-read policies
- Revokes `anon` / `authenticated` grants on tables and RPCs

See [`SECURITY.md`](SECURITY.md) for the full open-source security model and deploy steps.

## Refresh materialized view

Schedule via pg_cron, GitHub Actions daily sync, or run after pipeline ingest:

```sql
SELECT public.refresh_player_club_intersections();
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Valid player marked wrong | Deploy `validate-answer`; run migrations `007`, `013` |
| Same 6 teams every day (demo grid) | API failed → client fell back to demo; run migrations `014`–`015`, deploy `daily-puzzle`, clear app cache (v6) |
| `ensure_daily_puzzle` HTTP 500 | Run `./scripts/run_migrations.sh 014 015`; verify `club_relationships` count > 0 |
| `deno.land` deploy error | Use `npm:@supabase/supabase-js@2` (already in repo) |
| DB deadlock during sync | Never run two `sync_api_football` / `apply-patches` jobs in parallel |
| Stale club UUIDs in app | Full app restart (cache key v6 invalidates old demo puzzles) |
