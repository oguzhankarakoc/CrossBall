# CrossBall — Game Modes Backlog & Club × Nationality Spec

**Document type:** Product design + technical pre-spec  
**Audience:** Product, Engineering, LiveOps  
**Version:** 1.0.0  
**Date:** July 2026  
**Status:** Planning (not implemented)

Related: [ARCHITECTURE.md](./ARCHITECTURE.md) §4 Game Modes, [PRODUCT_AUDIT.md](./PRODUCT_AUDIT.md) §13 Innovation Backlog.

---

## Executive summary

CrossBall’s long-term moat is the **intersection grid** — not separate mini-games. New modes should extend **axis types** (club, nationality, league, era, trophy) or **session modifiers** (speed, mystery, themed week) while reusing the existing grid UI, validation pipeline, and scoring engine.

This document defines:

1. A **12-mode prioritized backlog** scored by engagement, data cost, and premium fit.
2. A **full product spec** for the first recommended new axis: **Club × Nationality**.

---

## Scoring methodology

| Metric | Scale | Meaning |
|--------|-------|---------|
| **Engagement** | 1–10 | Retention, replay, shareability, “one more game” pull |
| **Data cost** | 1–5 | 1 = existing DB only · 3 = derived/batch · 5 = new paid ingest (trophies, stats) |
| **Premium fit** | Free · Freemium · Premium | Monetization placement without pay-to-win |
| **Priority** | P0–P4 | P0 shipped · P1 next quarter · P4 when revenue + data budget allow |
| **Complexity** | S · M · L · XL | Engineering estimate |

**Composite score (for sorting):** `Engagement × 2 − Data cost + Premium bonus`  
Premium bonus: Free = 0 · Freemium = 1 · Premium = 0.5 (breadth over exclusivity early).

---

## Part 1 — 12-mode prioritized backlog

| Rank | Mode | Axis / modifier | Engagement | Data cost | Premium fit | Priority | Complexity | Composite | Notes |
|------|------|-----------------|------------|-----------|-------------|----------|------------|-----------|-------|
| 1 | **Daily Classic** | Club × Club | 10 | 1 | Free | P0 ✅ | — | 19 | Core loop; global UTC puzzle |
| 2 | **Friend Challenge** | Club × Club | 9 | 1 | Free | P0 ✅ | M | 17 | Async viral; needs rematch polish |
| 3 | **Practice** | Club × Club | 8 | 1 | Freemium | P0 ✅ | M | 16 | Quota free · 4×4 premium |
| 4 | **Themed Week** | Club × Club + LiveOps | 8 | 1 | Freemium | P1 | M | 16 | “Premier League week”, “Derbi günü” — same engine, curated club pool |
| 5 | **Club × Nationality** | Club × Country | 9 | 1 | Freemium | P1 | L | 17 | **First new axis** — spec below |
| 6 | **Timeline Training** | Club × Club + career overlay | 7 | 1 | Premium | P0 ✅ | L | 14 | Shipped Phase 4; premium flag |
| 7 | **Blitz** | Any grid + 60s timer | 8 | 1 | Freemium | P2 | M | 16 | Session modifier; no new validation |
| 8 | **Club × League** | Club × “played in league X” | 8 | 2 | Freemium | P2 | L | 15 | Derive from career → club → league |
| 9 | **Mystery Row** | Hidden axis until row solved | 7 | 1 | Freemium | P2 | M | 14 | Modifier on existing puzzles |
| 10 | **Club × Era** | Club × decade (1990s…) | 7 | 2 | Premium | P3 | L | 13 | Date filter on career stints |
| 11 | **Glory Grid** | Club × Trophy (UCL, WC…) | 9 | 5 | Premium | P4 | XL | 13 | Requires `player_honors` ingest |
| 12 | **Reverse Training** | Given player → pick club pair | 6 | 1 | Free | P3 | M | 12 | Tutorial / onboarding mode |

### Recommended build order (post-launch)

```
Phase A (retention)     → Themed Week, share card, achievements UI
Phase B (first axis)    → Club × Nationality (this spec)
Phase C (modifiers)     → Blitz, Mystery Row
Phase D (second axis)   → Club × League
Phase E (revenue+)      → Club × Era, Glory Grid (trophy data)
```

### Modes intentionally excluded from top 12

| Idea | Why deferred |
|------|----------------|
| Manager axis (Guardiola × Mourinho) | No manager-stint data today |
| Stat axis (50+ PL goals) | Requires stats API |
| Transfer-path puzzle | Niche; high validation complexity |
| Co-op realtime | XL social infra; after DAU proof |
| AI trivia quiz | Off-brand; splits learning curve |

---

## Part 2 — Club × Nationality product spec

**Codename:** `nationality_grid`  
**Player-facing name:** **World XI** (EN) · **Dünya 11’i** (TR) · **World XI** (DE)  
**Tagline:** *Name players who wore the club **and** fly the flag.*

### 2.1 Positioning

| Dimension | Choice |
|-----------|--------|
| Core fantasy | “I know which Brazilians played for Chelsea” |
| Difficulty vs classic | Slightly easier per cell (nationality narrows search) but broader cultural appeal |
| Cannibalization | Does **not** replace daily; separate weekly or practice entry |
| Brand fit | Same grid, same badges; row/column headers mix club badges + flag chips |

### 2.2 Validation rules

A cell at `(row, col)` is **correct** when the submitted player satisfies **both** constraints:

| Layout option | Row | Column | Rule |
|---------------|-----|--------|------|
| **A (recommended v1)** | Club | Nationality | Senior stint at row club **AND** `players.nationality_code = col country` |
| B (alternate) | Nationality | Club | Same logic, transposed |

**Senior stint definition** — identical to classic mode ([ARCHITECTURE.md](./ARCHITECTURE.md) §5):

- `player_career_history`: `is_senior = true`, `is_youth = false`, `is_reserve = false`
- Loan spells at senior level **count**
- Youth / B team **excluded**

**Nationality definition (v1):**

- Single field: `players.nationality_code` (ISO 3166-1 alpha-2)
- Dual nationality: **not supported in v1** — FIFA primary nationality from SoFIFA only
- Naturalized players: whatever SoFIFA/patch data says (document in FAQ)

**Explicit non-rules (v1):**

- Does **not** require cap for that nation
- Does **not** require playing during a specific era (use Club × Era mode later)
- Does **not** accept “played for national team” without club stint

**Pseudo-validation:**

```sql
player_played_for_clubs(player_id, row_club_ref)
AND players.nationality_code = col_nationality_code
```

### 2.3 Grid layouts

| Variant | Grid | Access | Schedule |
|---------|------|--------|----------|
| **World XI Weekly** | 3×3 | Free | One global puzzle per week (Monday UTC) |
| **World XI Practice** | 3×3 | Free (quota) | On-demand from practice pool |
| **World XI Elite** | 4×4 | Premium | Unlimited practice + no ads |

**Header UI:**

```
         🇫🇷 France    🇧🇷 Brazil    🇵🇹 Portugal
[Chelsea badge]
[Arsenal badge]
[Real badge]
```

- Club row: existing `ClubHeaderCell` / `PuzzleClubTile`
- Nationality column: new `NationalityHeaderCell` — flag emoji + localized country name (reuse `CountryFlags` from search)

### 2.4 Difficulty tiers

Minimum **valid answer count per cell** (same philosophy as classic engine):

| Tier | Min answers | Typical feel | Use |
|------|-------------|--------------|-----|
| Easy | 12+ | Many obvious names | Onboarding week |
| Medium | 6+ | Requires real fan knowledge | Default practice |
| Hard | 4+ | Specialist knowledge | Weekly challenge |
| Legend | 2–3 | Expert / niche | Premium showcase |

**Generation constraints (quality gate):**

| Rule | Threshold |
|------|-----------|
| Min countries per puzzle | 3 distinct nationality codes |
| Max same nationality | 1 per column (3×3) |
| Min leagues represented in clubs | 2 (avoid all-Premier monotony) |
| Avoid overused pair | Same club+nationality pair not in last 14 days |
| Quality score | ≥ 80 (slightly relaxed vs club×club 85 — smaller graph) |
| Human simulation | ≥ 85 |

**Difficulty score formula (relationship table):**

```
difficulty_score = log(valid_player_count + 1) / log(50)
-- higher count = easier cell
```

### 2.5 Scoring & hints

Reuse existing scoring engine (rarity tiers, cell score, streak multipliers).

| Hint type | Available in World XI? | Notes |
|-----------|------------------------|-------|
| `first_letter` | Yes | Unchanged |
| `position` | Yes | Unchanged |
| `nationality` | **No** | Column reveals nationality — redundant |
| `career_league` | Yes | Still useful |
| `retired_status` | Yes | Unchanged |
| `career_club` | Yes (premium) | “Also played for…” — different from row club |

**New hint (v2 optional):** `continent` — “This player is from South America” (when column is hidden in Mystery variant).

### 2.6 User-facing copy

| Key | EN | TR | DE |
|-----|----|----|-----|
| `modeWorldXiTitle` | World XI | Dünya 11'i | World XI |
| `modeWorldXiSubtitle` | Club meets country | Kulüp ve milliyet | Verein trifft Nation |
| `ruleWorldXi` | Name a player who played for **{club}** and is **{nationality}**. | **{club}**'de oynayan **{nationality}** bir oyuncu yaz. | Nenne einen Spieler, der für **{club}** spielte und **{nationality}** ist. |
| `worldXiWeeklyBadge` | Weekly | Haftalık | Wöchentlich |

### 2.7 Entry points (UI)

| Location | Component | Action |
|----------|-----------|--------|
| Home | New card below Daily | “World XI — This week” |
| Practice hub | Mode picker chip | “World XI” |
| LiveOps banner | When `world_xi_week` event active | Deep link to puzzle |

**Do not** add a 5th bottom-nav tab in v1 — keeps navigation simple.

### 2.8 LiveOps themes (examples)

| Week theme | Club pool | Nationality pool |
|------------|-----------|------------------|
| Premier League diaspora | Top 6 PL clubs | FR, BR, ES, NG, BE, HR |
| Latin link | Real, Barça, Atlético, Sevilla | AR, BR, UY, CO, MX |
| Serie A imports | Inter, Milan, Juve, Roma, Napoli | FR, AR, NL, SN, RS |
| World Cup hangover | Clubs of WC finalists | WC nations only |

Feature flag: `world_xi_mode` in `liveops_feature_flags` (default off until launch).

### 2.9 Monetization

| Surface | Free | Premium |
|---------|------|---------|
| Weekly World XI | 1/week | Same |
| Practice World XI | 3/day quota | Unlimited |
| 4×4 grid | Locked | Unlocked |
| Ads | Interstitial on complete | None |
| Hints | Ad-gated | `career_club` hint included |

No pay-to-win: premium does not reveal answers.

### 2.10 Technical implementation sketch

**Database (migration `026_world_xi_mode.sql` — not yet created):**

```sql
-- Extend puzzle_mode enum
ALTER TYPE puzzle_mode ADD VALUE IF NOT EXISTS 'world_xi';

-- Precomputed relationships (batch after ETL)
CREATE TABLE club_nationality_relationships (
  club_id           UUID NOT NULL REFERENCES clubs(id),
  nationality_code  CHAR(2) NOT NULL,
  valid_player_count INT NOT NULL DEFAULT 0,
  player_ids        UUID[] NOT NULL DEFAULT '{}',
  difficulty_score  NUMERIC(4,2),
  PRIMARY KEY (club_id, nationality_code)
);

CREATE INDEX idx_club_nat_rel_count
  ON club_nationality_relationships (valid_player_count DESC);

-- Refresh function (called from pipeline post-load)
CREATE OR REPLACE FUNCTION refresh_club_nationality_relationships() ...
```

**Validation RPC:**

```sql
CREATE OR REPLACE FUNCTION validate_player_club_nationality(
  p_player_id UUID,
  p_club_ref TEXT,
  p_nationality_code CHAR(2)
) RETURNS BOOLEAN AS $$
  SELECT player_played_for_clubs(p_player_id, p_club_ref)
     AND EXISTS (
       SELECT 1 FROM players p
       WHERE p.id = p_player_id
         AND p.nationality_code = p_nationality_code
     );
$$;
```

**Puzzle generation:**

- Mirror `pick_valid_puzzle_clubs` → `pick_valid_world_xi_axes(club_ids[], nationality_codes[])`
- Store columns in new table `puzzle_col_nationalities` OR generic `puzzle_axes(axis_type, axis_index, ref)`
- v1 shortcut: add `puzzle_col_nationalities(puzzle_id, col_index, nationality_code CHAR(2))`

**Edge functions:**

| Function | Change |
|----------|--------|
| `validate-answer` | Accept `axis_mode: 'world_xi'` + nationality column ref |
| `practice-puzzle` | Filter `mode = 'world_xi'` |
| New: `world-xi-weekly` | `ensure_world_xi_puzzle(week_start_date)` |

**Flutter:**

| Area | Change |
|------|--------|
| `PuzzleMode` enum | Add `worldXi` |
| `puzzle_grid.dart` | Render nationality headers on col axis when mode = worldXi |
| New widget | `NationalityHeaderCell` (flag + name) |
| `puzzle_repository_impl.dart` | Route to world-xi endpoints |
| l10n | Keys in §2.6 |

**Pipeline (`data_pipeline/`):**

After `load.py`:

```bash
psql "$DATABASE_URL" -c "SELECT refresh_club_nationality_relationships();"
```

No new external API required — uses existing `players.nationality_code` + career history.

### 2.11 Rollout plan

| Stage | Scope | Gate |
|-------|-------|------|
| **Alpha** | Internal; 10 hand-picked 3×3 puzzles | Relationships table populated |
| **Beta** | Feature flag 5% users; practice only | Validation error rate < 0.1% |
| **Launch** | Weekly World XI + practice; home card | D7 retention on beta ≥ daily baseline |
| **v1.1** | Themed LiveOps weeks | Event config in `liveops_events` |

### 2.12 Success metrics

| Metric | Target (8 weeks post-launch) |
|--------|------------------------------|
| World XI weekly participation | ≥ 25% of DAU |
| Completion rate | ≥ 60% of starters |
| Avg session time | 4–7 min (similar to daily) |
| Premium conversion lift | +5% vs control |
| Share rate | ≥ 8% of completions |

### 2.13 Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Wrong nationality in SoFIFA | Manual patches for top 50 disputed players |
| Too-easy cells (BR + Chelsea) | Legend tier + quality gate min 4 |
| Too-hard cells (SM + Burnley) | Generator rejects pairs below tier minimum |
| Confusion with classic rules | Persistent rule banner on first cell tap |
| Sparse graph | Fall back to medium tier; exclude nations with < 20 players in DB |

### 2.14 QA checklist

- [ ] Player with senior stint validates; youth stint alone fails
- [ ] Loan spell at club counts
- [ ] Wrong nationality fails even if correct club
- [ ] Correct club + nationality at different life periods still passes
- [ ] Search modal shows flag consistent with validation
- [ ] Demo/offline mode uses seeded world-xi puzzle
- [ ] l10n TR/DE rule strings fit without overflow on small phones
- [ ] Premium 4×4 generates 16 valid cells

---

## Appendix A — Generic axis architecture (future)

When adding League, Era, or Trophy axes, prefer one abstraction:

```
puzzle_axes (
  puzzle_id UUID,
  axis_index SMALLINT,      -- 0..n row, 100..100+n col
  axis_kind TEXT,           -- 'club' | 'nationality' | 'league' | 'era' | 'trophy'
  ref_id TEXT,              -- club slug, ISO code, league id, decade, trophy id
  PRIMARY KEY (puzzle_id, axis_index)
)
```

World XI v1 may use `puzzle_col_nationalities` for speed; refactor when axis #3 ships.

---

## Appendix B — Cross-reference to shipped modes

| `puzzle_mode` enum | Status | Doc |
|--------------------|--------|-----|
| `daily` | Shipped | ARCHITECTURE §4 |
| `practice` | Shipped | ARCHITECTURE §15 Step 9 |
| `challenge` | Shipped | ARCHITECTURE §14 |
| `timeline` | Shipped Phase 4 | migration 024 |
| `world_xi` | **Planned** | This document |

---

*Next implementation step: migration 026 + `refresh_club_nationality_relationships()` + Flutter `NationalityHeaderCell`. Switch to Agent mode and reference this doc to build.*
