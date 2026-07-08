# Daily Puzzle — Business Flow & Architecture

## Overview

The global daily puzzle is a **single immutable grid per UTC calendar day**. All players see the same clubs and cell IDs for that date. Fairness depends on consistent server state and clients never playing stale cached grids.

## Lifecycle (UTC)

| Phase | Time (TR UTC+3) | Server `daily_puzzle_rollout.status` | Client behaviour |
|-------|-----------------|--------------------------------------|------------------|
| Reset | 03:00 | `generating` (pipeline begins) | Show "Yeni bulmaca hazırlanıyor" — **no play** |
| Build | 03:00–06:00 | `generating` | Poll rollout; clear local + offline cache |
| Ready | ~06:00+ | `ready` | Fetch puzzle, start/resume session |
| Play | Rest of day | `ready` | Immutable layout; resume allowed |
| Next day | 03:00 | cycle repeats | Invalidate yesterday snapshot |

GitHub Action: `.github/workflows/data-sync-daily.yml` (cron `0 0 * * *` UTC).

Pipeline steps (`scripts/run_scheduled_sync.sh`):

1. `daily-rollout-begin` → `generating`
2. API-Football sync (~3 min)
3. `ensure-daily` → `ensure_daily_puzzle()` if no published puzzle for `CURRENT_DATE`

## Immutability contract

Once a daily puzzle is `is_published = TRUE` for a `puzzle_date`:

- Row/col clubs and `puzzle_cells` **must not** be updated or deleted (DB trigger `040_daily_puzzle_integrity.sql`).
- `puzzle_hash` + club UUIDs define `layoutFingerprint` on the client.
- If client cache fingerprint ≠ server → abandon session (`force_new`), clear snapshot.

## Client layers

```
Home → rollout status (dailyPuzzleRolloutProvider)
     → PuzzleScreen.loadPuzzle()
         → DailyPuzzleContract.shouldBlockLoad()  [gate]
         → getDailyPuzzle(forceRefresh)           [network]
         → hydratePuzzleCells()                   [authoritative cell UUIDs]
         → layout fingerprint check               [session reset if mismatch]
         → startSession(forceNew?)                [server session]
         → ActivePuzzleCache snapshot             [progress only, not layout]
```

Key files:

- `lib/core/daily/daily_puzzle_contract.dart` — business rules
- `lib/features/puzzle/presentation/puzzle_providers.dart` — load + session
- `lib/core/cache/offline_cache.dart` — UTC date keyed daily cache

## Session rules

| Scenario | Action |
|----------|--------|
| Same day, same layout, valid cells | Resume session |
| Layout fingerprint changed | `force_new` session, timer reset |
| `cell_not_found` from API | Refresh cells once, retry; else reload |
| Rollout not `ready` | Block play, show refresh panel |

## Generation diversity

Primary: `generate_puzzle()` (quality tiers, recent-hash dedup).

Fallback: `generate_daily_puzzle_fast()` — now excludes:

- `puzzle_hash` seen in last 30 days
- Club IDs used in daily puzzles in last 14 days
- Per-date `setseed()` jitter

## Deploy checklist

```bash
# 1. DB migration
./scripts/run_migrations.sh 040

# 2. Edge functions
supabase functions deploy daily-puzzle
supabase functions deploy start-session
supabase functions deploy request-hint
supabase functions deploy puzzle-by-id

# 3. Client: full restart (not hot reload)
flutter run
```

## Monitoring

```bash
python3 scripts/verify_daily_puzzle.py
gh run list --workflow=data-sync-daily.yml
```
