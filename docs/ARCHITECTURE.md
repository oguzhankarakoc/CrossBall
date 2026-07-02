# CrossBall — Technical Architecture

**Version:** 1.0.0  
**Status:** Production MVP  
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
│   ├── theme/           # Dark football theme
│   └── utils/           # String normalization, scoring math
├── shared/
│   └── widgets/         # Reusable UI components
└── features/
    ├── auth/
    ├── onboarding/
    ├── home/
    ├── puzzle/
    ├── search/
    ├── challenge/
    ├── stats/
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
| Unlimited Practice | Any | Premium | None |

---

## 5. Validation Engine

### Inclusion rules

- Senior official appearances (first team)
- Loan spells at senior level

### Exclusion rules

- Youth teams (U19, U21, etc.)
- Reserve / B teams
- Trial-only or unverified appearances

### Implementation

Server-side validation via `validate-answer` edge function queries `player_career_history` with `is_senior = true AND is_youth = false AND is_reserve = false`.

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

## 7. Search System

### Requirements

- Fuzzy, accent-insensitive, case-insensitive
- Target latency: 50–150 ms perceived

### Backend

- PostgreSQL `pg_trgm` on `normalized_name`
- GIN index on `search_vector` (tsvector)
- Edge function `search-players` with `similarity()` ranking

### Client

- Debounce 200 ms
- Local recent picks cache (SharedPreferences)
- Popular picks from `rarity_stats` aggregation
- Optional local search index file for offline typeahead

### Normalization

```
"Özil" → "ozil"
"Cesc Fàbregas" → "cesc fabregas"
```

---

## 8. Hint System

| Hint | Cost | Reveals |
|------|------|---------|
| 1 | 1 rewarded ad | Nationality |
| 2 | 1 rewarded ad | Position |
| 3 | Premium or 2nd ad | First letter pattern |

Hints stored per session; cannot stack same hint type.

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

- Daily puzzle payload (JSON file)
- Recent player picks (SharedPreferences)
- User stats snapshot
- Search index subset (top 5k players)

### Sync strategy

- On reconnect: flush pending answers, refresh stats
- Daily puzzle TTL: until next UTC midnight
- Cache invalidation on version bump

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
  "puzzle_id": "uuid",
  "row_club_id": "uuid",
  "col_club_id": "uuid",
  "player_id": "uuid",
  "session_id": "uuid"
}

// Response
{
  "correct": true,
  "player_name": "Pedro",
  "usage_percentage": 67.2,
  "rarity_tier": "common",
  "rarity_score": 32.8,
  "already_used_in_session": false
}
```

### GET `/functions/v1/search-players?q=ozil&limit=20`

```json
{
  "results": [{
    "id": "uuid",
    "name": "Mesut Özil",
    "nationality_code": "DE",
    "primary_position": "Midfielder",
    "clubs_preview": ["Arsenal", "Real Madrid"]
  }],
  "latency_ms": 42
}
```

### POST `/functions/v1/hint`

```json
// Request
{ "session_id": "uuid", "cell_row": 0, "cell_col": 1, "hint_type": "nationality" }
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

## 15. Puzzle Generation

### Pipeline

1. Curators seed high-quality club pairs
2. Algorithm generates candidate grids from top-100 clubs
3. For each cell: count valid intersections via career history join
4. Reject if any cell < 3 valid answers
5. Score difficulty: inverse of average valid answers per cell
6. Store in `puzzles` + `puzzle_cells`

### Fairness rules

- Minimum 3 valid answers per cell
- Ideal 8+ valid answers
- No duplicate clubs in same row/column
- Balanced nationality distribution in valid answer set

---

## 16. Data Pipeline

Python batch job (`data_pipeline/`):

1. Fetch raw data (CSV/API)
2. Normalize club names → slug
3. Filter youth/reserve appearances
4. Deduplicate players
5. Validate referential integrity
6. Upsert to PostgreSQL

Deterministic: same input → same output hash.

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
| Edge functions | Supabase CLI deploy |
| Pipeline | GitHub Actions cron / manual |
| Analytics | PostHog cloud |

---

## 20. Scalability Path

| Phase | Users | Changes |
|-------|-------|---------|
| MVP | 0–10k | Single Supabase project, edge functions |
| Growth | 10k–500k | Read replicas, Redis search cache |
| Scale | 500k+ | CDN for static assets, dedicated search (Typesense) |

---

*CrossBall Architecture v1.0.0 — production MVP*
