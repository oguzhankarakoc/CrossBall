# CrossBall — Technical Architecture

**Version:** 1.2.0  
**Status:** Production MVP (Phases 0–5 shipped)  
**Tagline:** Connect clubs. Prove your football IQ.

---

## 1. System Overview

CrossBall is a football intersection puzzle game. Players solve grid puzzles by naming footballers who played for both clubs at each cell intersection. The product targets iOS and Android via Flutter, with Supabase as the backend platform.

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Client (iOS/Android)            │
│  presentation → domain ← data                               │
│                    ↑                                        │
│                   core (theme, routing, cache, analytics)   │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTPS / WebSocket (future)
┌──────────────────────────▼──────────────────────────────────┐
│                        Supabase                             │
│  PostgreSQL │ Auth │ Storage │ Edge Functions │ Realtime    │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│              Python Data Pipeline (batch)                   │
│  ingest → normalize → validate → load                       │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Client Architecture (Clean Architecture)

### Layer responsibilities

| Layer | Responsibility | Dependencies |
|-------|----------------|--------------|
| **presentation** | Screens, widgets, Riverpod providers, UI state | domain, core |
| **domain** | Entities, repository interfaces, use cases, business rules | core only |
| **data** | Supabase/API implementations, local cache, DTOs | domain, core |
| **core** | Theme, routing, config, errors, utils, analytics abstraction | none |

### Dependency rule

Dependencies point inward. Domain never imports Flutter or Supabase.

### Folder structure

```
lib/
├── core/
│   ├── config/          # AppConfig, env
│   ├── constants/       # Game rules, scoring thresholds
│   ├── errors/          # Failure types
│   ├── cache/           # Offline cache manager
│   ├── network/         # Supabase client provider
│   ├── analytics/       # Event tracking abstraction
│   ├── routing/         # GoRouter
│   ├── theme/           # Light Pitch, Dark Stadium, contrast-safe typography
│   ├── club_identity/   # Original badge registry, tokens, display resolver
│   └── utils/           # String normalization, scoring math, flags
├── shared/
│   └── widgets/         # Club badges, glass UI, search cards, player avatar
└── features/
    ├── auth/
    ├── onboarding/
    ├── home/
    ├── puzzle/
    ├── search/
    ├── challenge/
    ├── stats/
    ├── economy/
    ├── liveops/
    ├── social/          # activity feed, career timeline, football facts
    ├── tournament/
    ├── leaderboard/
    ├── settings/
    ├── premium/
    └── ads/
```

Each feature follows:

```
feature/
├── domain/       # entities, repository interfaces
├── data/         # remote/local datasources, repository impl
└── presentation/ # screens, providers, widgets
```

---

## 3. Authentication

### Anonymous-first model

- On first launch, generate `user_uuid` (UUID v4) via `flutter_secure_storage`
- No mandatory login; profile syncs to `users` table on first API call
- Future: Apple Sign In, Google Sign In linked to same profile

### Identity flow

```
App launch → SecureStorage read/write UUID
          → Supabase upsert users row (user_uuid)
          → RLS policies scoped to user_uuid header
```

---

## 4. Game Modes

| Mode | Grid | Access | Ads |
|------|------|--------|-----|
| Daily Challenge | 3×3 | Free | Interstitial on complete |
| Friend Challenge | 3×3 | Free | Interstitial on complete |
| Practice | 3×3 | Free (limited) | Every N games |
| Practice | 4×4 | Premium | None |
| Timeline | Career years overlay | Premium (flag) | None |
| Unlimited Practice | Any | Premium | None |

**Planned modes:** See [GAME_MODES_BACKLOG.md](./GAME_MODES_BACKLOG.md) — 12-mode prioritized backlog and full **Club × Nationality (World XI)** product spec.

---

## 4b. Original Club Identity System

CrossBall never displays official club logos. Every club uses a **procedural CrossBall badge** rendered in Flutter (`CustomPaint`).

### Resolution order

1. `assets/clubs/{slug}/metadata.json` override (optional)
2. `ClubIdentityData.bySlug` — **105 curated** slugs (colors + abstract symbol)
3. API fields from `clubs` table (`badge_primary_color`, `badge_icon_type`, …)
4. Deterministic hash fallback for unknown slugs

Curated Flutter symbols **override** generic DB `abstract_shield` values.

### Symbol types (legal-safe)

Abstract geometry only: stripes, crown, lion, orb, chevron, diamond, star, waves, cross, flame, wings, compass, oak, eagle, shield.

### Client components

| Widget | Use |
|--------|-----|
| `ClubBadge` | Core badge renderer with visual states |
| `ClubHeaderCell` / `PuzzleClubTile` | Puzzle grid headers (badge + name) |
| `ClubIdentityChip` | Compact list/search pill |
| `LeaderboardClubIcon` | Stats, mastery, leaderboard rows |

### Design tokens

`ClubBadgeTokens` — shared proportions, glow, animation, high-contrast helpers. All badges use the same rounded-shield silhouette.

### Database

Migration `025_club_identity_full_coverage.sql` syncs `badge_icon_type` + accent for all 105 seed clubs.

---

## 5. Validation Engine

### Rule

A cell answer is correct when the player has **senior first-team appearances at both the row club and the column club**. The player does not need to have played only for those two clubs.

### Inclusion rules

- Senior official appearances (first team)
- Loan spells at senior level

### Exclusion rules

- Youth teams (U19, U21, etc.)
- Reserve / B teams
- Trial-only or unverified appearances

### Implementation

Server-side validation via `validate-answer` edge function:

1. Resolve club references through RPC `club_ids_equivalent_to` (merges legacy slug aliases like `fc-barcelona` → `barcelona`)
2. Query `player_career_history` with `is_senior = true AND is_youth = false AND is_reserve = false` for both clubs
3. Update rarity stats only when `puzzle_cell_id` is a valid UUID

Client displays result; never trusts client-only validation for competitive modes.

---

## 6. Scoring System

### Rarity score

```
rarity_score = max(0, 100 - usage_percentage)
```

### Rarity tiers

| Tier | Usage % | Color |
|------|---------|-------|
| Common | >50% | Gray |
| Rare | 25–50% | Blue |
| Epic | 10–25% | Purple |
| Legendary | 3–10% | Gold |
| Mythic | <3% | Red-gold glow |

### Final score

```
final_score = (rarity_score × speed_bonus) - mistake_penalty

speed_bonus:
  < 30s per cell  → 1.3
  < 60s per cell  → 1.15
  < 120s per cell → 1.0
  else            → 0.85

mistake_penalty: 15 points per wrong attempt on cell
```

---

## 6b. Game Economy Engine (GEE)

Independent backend-driven progression system. **No hardcoded reward values in the client** — all tuning lives in `economy_config`.

### Responsibilities

| System | Tables / RPCs |
|--------|----------------|
| XP & levels | `economy_level_thresholds`, `player_progression` |
| Competitive rating | Separate from XP; capped deltas in `economy_config.rating` |
| Leagues | `economy_leagues` (Bronze → Legend) |
| Streaks | `player_progression.current_streak`, milestone rewards in config |
| Achievements | `economy_achievement_definitions`, `player_achievements` |
| Missions | `economy_mission_definitions`, `player_missions` |
| Seasons | `economy_seasons`, `player_season_stats` |
| Rewards | `economy_reward_types`, `player_rewards_granted` |
| Analytics | `economy_events_log` |

### Event processing

Puzzle completion triggers `gee_process_event(user_uuid, event_type, payload)` from the `complete-session` edge function.

Event types: `daily_completed`, `practice_completed`, `puzzle_completed`, `challenge_won`, `challenge_lost`.

Payload includes: score, mistakes, hints, duration, difficulty tier, quality score, rarity counts, perfect-game flag.

### Fair play

`economy_config.premium` locks `xp_multiplier`, `rating_multiplier`, and `score_multiplier` at **1.0**. Premium benefits are cosmetic/QoL only.

### Client integration

```
lib/features/economy/
├── domain/player_progression.dart
└── data/economy_repository_impl.dart
```

- `playerProgressionProvider` fetches `economy-profile` edge function
- Stats screen shows level, XP, rating, league
- Offline sync caches progression from `complete-session` economy response

---

## 6c. LiveOps Engine (LOE)

Independent remote operations layer for events, config, and feature flags. Communicates with other engines but does not couple to them.

| System | Tables / RPCs |
|--------|----------------|
| Remote config | `liveops_config` |
| Feature flags | `liveops_feature_flags`, `loe_evaluate_flag()` |
| Events | `liveops_events`, `liveops_event_i18n` |
| Collections | `liveops_puzzle_collections`, i18n |
| Community goals | `liveops_community_goals` |
| Announcements | `liveops_announcements`, i18n |
| A/B tests | `liveops_ab_experiments`, `liveops_ab_assignments` |
| Content rotation | `liveops_content_rotation` |
| Football calendar | `liveops_football_calendar` |
| Analytics | `liveops_analytics_events`, `loe_track_event()` |

### Client snapshot

`loe_get_snapshot(user, locale, platform, country, app_version)` returns config, resolved flags, active events, announcements, collections, community goals, rotation, and experiments.

Edge function: `liveops-config` (GET)

### Failsafe

Client falls back to cached snapshot, then `LiveOpsDefaults` — puzzles always playable.

---

## 7. Search System

### Requirements

- Fuzzy, accent-insensitive, case-insensitive
- Target latency: 50–150 ms perceived
- **Spoiler-free:** no suggestions before the user types (no recent, popular, or cell suggestions on modal open)

### Backend

- PostgreSQL `pg_trgm` on `normalized_name`
- GIN index on `search_vector` (tsvector)
- Edge function `search-players` with `similarity()` ranking
- Autocomplete only when `q` length ≥ 2

### Client

- Debounce 200 ms
- Empty query shows placeholder only (`Search player...`)
- Hints are the only assist mechanism during gameplay

### Normalization

```
"Özil" → "ozil"
"Cesc Fàbregas" → "cesc fabregas"
```

---

## 8. Hint System

All hints require **rewarded ads** for free users (except premium-only career club reveal). Hints never reveal player names or valid answers.

| Order | Hint | Access |
|-------|------|--------|
| 1 | Nationality | Rewarded ad |
| 2 | Primary position | Rewarded ad |
| 3 | First letter pattern | Rewarded ad |
| 4 | Career league | Rewarded ad |
| 5 | Retired or active | Rewarded ad |
| 6 | Additional career club | Premium only |

Hints use a deterministic sample player per cell/session so values stay consistent. Stored per session in `session_hints`.

---

## 9. Friend Challenge (Async Multiplayer)

```
Player 1: solve puzzle → POST /challenge-create → share link
Player 2: open challenge/abc123 → same puzzle → solve → compare scores
```

### Winner formula

```
challenge_score = final_score - (mistakes × 10) - (hints_used × 5)
```

Higher score wins. Ties broken by faster total time.

---

## 10. Anti-Cheat

Competitive sessions track:

- `started_at` — timer starts on puzzle open
- `background_duration_ms` — app lifecycle pauses don't stop timer
- `inactive_periods` — no interaction > 2 min flagged
- `total_duration_ms` — suspicious if > 40 min for 3×3

### Flags

| Condition | Action |
|-----------|--------|
| duration > 40 min (3×3) | `is_suspicious = true` |
| background > 50% of duration | flag |
| inactivity > 3 periods | flag |

Suspicious sessions excluded from leaderboards; challenge shows integrity warning.

---

## 11. Monetization

### Ad placement

| Type | Screens | Never on |
|------|---------|----------|
| Banner | Home, Stats, Result | Gameplay |
| Interstitial | Post-game, every 3 practice | During puzzle |
| Rewarded | Hints, extra practice, reroll | — |

Premium (`is_premium = true`) removes all ads.

---

## 12. Offline Support

### Cached locally

- Daily puzzle payload (SharedPreferences + JSON file, cache key versioned)
- Recent player picks (SharedPreferences)
- User stats snapshot
- Search index subset (top 5k players)

### Sync strategy

- On reconnect: flush pending answers, refresh stats
- Daily puzzle TTL: until next UTC midnight
- Cache invalidation on version bump (`cache_daily_puzzle_v3`)
- Invalid puzzle cache (non-UUID club IDs) is rejected and refetched

---

## 13. Analytics Events

| Event | Properties |
|-------|------------|
| `puzzle_started` | mode, grid_size |
| `puzzle_completed` | score, duration, hints |
| `answer_submitted` | correct, rarity_tier, latency_ms |
| `search_query` | query_length, result_count, latency_ms |
| `hint_used` | hint_type, ad_watched |
| `ad_impression` | ad_type, placement |
| `premium_viewed` | source |
| `onboarding_completed` | skipped |
| `challenge_created` | challenge_id |
| `challenge_completed` | won |

Integration: PostHog (primary) with Firebase Analytics fallback via abstraction.

---

## 14. Backend API Contracts

### GET `/functions/v1/daily-puzzle`

```json
// Response
{
  "puzzle_id": "uuid",
  "date": "2026-07-02",
  "grid_size": 3,
  "row_clubs": [{"id": "...", "name": "FC Barcelona", "slug": "barcelona"}],
  "col_clubs": [{"id": "...", "name": "Chelsea FC", "slug": "chelsea"}],
  "cells": [{"row": 0, "col": 0, "min_answers": 5, "difficulty": 0.42}]
}
```

### GET `/functions/v1/challenge/:id`

Same shape as daily puzzle + `creator_score`, `creator_uuid`.

### POST `/functions/v1/validate-answer`

```json
// Request
{
  "row_club_id": "uuid-or-slug",
  "col_club_id": "uuid-or-slug",
  "player_id": "uuid",
  "puzzle_cell_id": "uuid",
  "session_id": "uuid"
}

// Response
{
  "correct": true,
  "player_name": "Robert Lewandowski",
  "usage_percentage": 67.2,
  "rarity_tier": "common",
  "rarity_score": 32.8,
  "already_used_in_session": false
}
```

### GET `/functions/v1/search-players?q=ozil&limit=20&row_club_id=...&col_club_id=...`

```json
{
  "results": [{
    "id": "uuid",
    "name": "Mesut Özil",
    "nationality_code": "DE",
    "primary_position": "Midfielder",
    "clubs": [{"name": "Arsenal", "slug": "arsenal"}],
    "matches_row_club": true,
    "matches_col_club": false
  }],
  "latency_ms": 42
}
```

### POST `/functions/v1/request-hint`

```json
// Request
{ "session_id": "uuid", "puzzle_cell_id": "uuid", "row_club_id": "uuid", "col_club_id": "uuid", "hint_type": "nationality" }
// Response
{ "hint_value": "Brazil", "hints_used": 1 }
```

### POST `/functions/v1/challenge-create`

```json
// Request
{ "puzzle_id": "uuid", "creator_score": 842, "session_id": "uuid" }
// Response
{ "challenge_id": "abc123", "share_url": "crossball://challenge/abc123" }
```

### GET `/functions/v1/stats?user_uuid=...`

```json
{
  "games_played": 42,
  "current_streak": 5,
  "best_streak": 12,
  "total_score": 18420,
  "rarity_breakdown": {"legendary": 8, "mythic": 2}
}
```

---

## 15. Puzzle Generation Engine

Backend-driven only — the Flutter client never generates puzzles.

### Step 1: Club relationship graph

`refresh_club_relationships()` builds pairwise senior-club relationships from `player_career_history`:

| Column | Purpose |
|--------|---------|
| `club_a_id`, `club_b_id` | Canonical pair (a < b) |
| `valid_player_count` | Intersection size |
| `player_ids` | UUID array of valid players |
| `difficulty_score` | Derived from count (more players = easier) |

### Step 2: Precompute on ETL

After every data load, the pipeline runs:

1. `refresh_player_club_intersections()`
2. `refresh_club_relationships()`

### Step 3–4: Generate from relationships

`generate_puzzle(mode, grid_size, difficulty_tier)` (migrations `014`–`015`):

1. **`pick_valid_puzzle_clubs`** — selects row/col clubs from `club_relationships` graph (top-N brute force), not random sampling
2. Structural validation: every cell meets tier minimum via `get_club_relationship`
3. **Quality gate:** `evaluate_puzzle_candidate` — quality ≥ 85 and human simulation ≥ 90
4. **Daily fallback:** if strict gate fails after max attempts, publishes best candidate (quality ≥ 60, human ≥ 65) with `relaxed_quality_gate` flag
5. Reject duplicate `puzzle_hash` in last 30 days; retry with shuffled club order

`ensure_daily_puzzle(date)` tries tiers in order: **hard → legend → medium** (medium often too sparse for current career data volume).

### Step 5: Difficulty tiers (minimum valid answers per cell)

| Tier | Min answers |
|------|-------------|
| Easy | 15+ |
| Medium | 8+ |
| Hard | 5+ |
| Legend | 3+ |

### Step 6: Duplicate prevention

`puzzle_hash` = MD5 of sorted club IDs. Rejected if hash exists in last 30 days.

### Step 7: Puzzle Quality Evaluation

After structural validation, every candidate is scored before publish:

| Score | Range | Threshold |
|-------|-------|-----------|
| **Puzzle Quality Score** | 0–100 | ≥ 85 to publish |
| **Human Simulation Score** | 0–100 | ≥ 90 to publish |

**Quality components** (weighted): avg valid answers, difficulty consistency, club/league/country diversity, popularity variety, rare-player opportunity, freshness, replay value, visual grid balance, avoidance of overused clubs and pairs.

**Human simulation components**: enjoyability, not too easy, not frustrating, rewards football knowledge, "aha" moments, rare discovery encouragement, handcrafted feel.

Candidates failing either threshold are rejected automatically. The engine tries up to **5000** attempts (quality over speed). Scores and full breakdown stored in `quality_score`, `human_simulation_score`, `quality_metrics` on `puzzles`.

RPC: `evaluate_puzzle_candidate(row_ids, col_ids, grid_size, min_answers)` — returns JSONB with scores and component breakdown.

### Step 8: Daily challenge

`ensure_daily_puzzle(date)` — **one global puzzle per UTC date**, same for all users (competitive leaderboard). Called by `daily-puzzle` edge function with default tier `hard`. Client uses cache `v6` and rejects demo fallback when Supabase is configured.

### Step 9: Practice mode

`select_practice_puzzle(user_uuid)` — weighted random from practice pool, penalizes recently played clubs, tier fallback on generation. Served by `practice-puzzle` edge function.

---

## 16. Data Pipeline

Python batch job (`data_pipeline/`):

| Stage | Source | Command |
|-------|--------|---------|
| Bulk history | Kaggle SoFIFA (FIFA 23 + EA FC 24) | `run-all` / `fetch-kaggle` |
| Recent transfers | API-Football `/transfers` (100 req/day free) | `sync-api-football` |
| Manual gaps | `data/raw/patches/career_patches.csv` | `apply-patches` |
| Automation | GitHub Actions cron | `data-sync-daily.yml`, `data-etl-weekly.yml` |

Flow after load:

1. Upsert clubs + players + `player_career_history` (conflict → **update** end dates)
2. `refresh_player_club_intersections()`
3. `refresh_club_relationships()` — powers puzzle generation
4. `ensure_daily_puzzle()` — after scheduled sync

**Priority when merging careers:** manual patch > API-Football > Kaggle SoFIFA.

Deterministic Kaggle transform: same input → same content hash. API responses cached 30 days on disk (`data/cache/api_football/`).

---

## 17. Security

- RLS on all user-scoped tables
- Edge functions validate `user_uuid` header
- Rate limiting on search (60 req/min)
- Answer validation server-side only for challenges
- No PII in analytics events

---

## 18. Testing Strategy

See `docs/TESTING.md`.

| Layer | Coverage target |
|-------|-----------------|
| Domain (scoring, rarity, anti-cheat) | 90%+ |
| Data (repositories, mappers) | 80%+ |
| Widget (critical flows) | Key paths |
| Integration | Daily puzzle E2E mock |
| Pipeline | Deterministic ingest tests |

---

## 19. Deployment

| Component | Target |
|-----------|--------|
| Flutter | App Store, Google Play |
| Supabase | Managed cloud project |
| Edge functions | `supabase functions deploy` (npm imports via `deno.json`) |
| Migrations | `./scripts/run_migrations.sh` (001–025) or `supabase db push` |
| Pipeline (daily) | GitHub Actions `data-sync-daily.yml` — API-Football + patches + daily puzzle |
| Pipeline (weekly) | GitHub Actions `data-etl-weekly.yml` — Kaggle bulk refresh |
| Pipeline (manual) | `./scripts/sync_api_football.sh`, `./scripts/run_etl.sh` |
| Analytics | PostHog cloud |

---

## 20. Scalability Path

| Phase | Users | Changes |
|-------|-------|---------|
| MVP | 0–10k | Single Supabase project, edge functions |
| Growth | 10k–500k | Read replicas, Redis search cache |
| Scale | 500k+ | CDN for static assets, dedicated search (Typesense) |

---

*CrossBall Architecture v1.2.0 — Phases 0–5, club identity, GEE, LOE, API-Football sync*
