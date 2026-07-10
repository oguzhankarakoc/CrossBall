# CrossBall — Game Modes Backlog & Market Plan

**Document type:** Product design · market analysis · technical pre-spec  
**Audience:** Product, Marketing, Engineering, LiveOps  
**Version:** 1.1.0  
**Date:** July 2026  
**Status:** Planning (modes beyond Classic / Practice / Challenge / Timeline not shipped)

Related: [ARCHITECTURE.md](./ARCHITECTURE.md) §4 Game Modes, [PRODUCT_AUDIT.md](./PRODUCT_AUDIT.md) §13 Innovation Backlog.

---

## Executive summary

CrossBall’s moat is the **intersection grid** — not a pile of disconnected mini-quizzes. New modes should extend **axis types** (club, nationality, league, era, trophy) or **session modifiers** (speed, mystery, themed week) while reusing grid UI, validation, search, scoring, and LiveOps.

**Product thesis (2026):** Immaculate Grid proved club×club daily grids. Competitors now flood the market with *Career Path*, *Connections*, and *Transfer Guess*. CrossBall wins by staying **grid-native**, adding **heterogeneous axes** (club × country first), and using LiveOps to tease “coming soon” modes without shipping half-baked side games.

This document covers:

1. **Market & competitor analysis** (Product Director / Growth lens)
2. **Prioritized mode backlog** scored for engagement, data cost, architecture fit
3. **Full Club × Nationality (“World XI”) spec**
4. **In-app panel / LiveOps teaser plan** for upcoming modes
5. **Generic axis architecture** for future modes

---

## Part 0 — Market analysis (July 2026)

### 0.1 Category map

| Cluster | Examples | Core loop | Threat to CrossBall |
|---------|----------|-----------|---------------------|
| **Grid intersection** | Immaculate Footy / Grid Footy, Sports Reference grids | Fill 3×3 with players matching row×col criteria; rarity score | **Direct** — same fantasy; web-first, data-rich (FBref) |
| **Group / Connections** | Athletic Connections Soccer, Football IQ Connections | Sort 16 tiles into 4 hidden groups | Adjacent — different skill; high shareability |
| **Career / transfer guess** | Football IQ Career Path, Transfer Guess, PlayFutbol | Reveal clubs/clues → name the player | Adjacent — we already have career data + timeline |
| **Clue chase / H2H** | Player Pursuit | Clues + streak + realtime | Different retention model; not grid |

### 0.2 What the market rewards right now

1. **Daily ritual** — one shared puzzle, streak, share card (Wordle DNA).
2. **Rarity / IQ flex** — obscure picks beat “everyone picks Messi”.
3. **World Cup / calendar hooks** — Athletic timed Connections Soccer to WC 2026; LiveOps calendar is our equivalent.
4. **Mode catalogs** — Football IQ markets “11 free daily games”; catalog drives ASO but **fragments brand learning**.
5. **Progressive clues** — Transfer Guess / Career Path monetize “one more hint” — we already have hint economy.

### 0.3 CrossBall positioning

| Strength we own | How to lean in |
|-----------------|----------------|
| Mobile-native grid + badges + search | Don’t become a web quiz clone |
| Obscurity / rarity scoring + GEE levels | Market “prove football IQ”, not “guess the celebrity” |
| Friend challenge + weekly rating | Social proof beyond solitary Wordle |
| LiveOps + feature flags | Soft-launch axes without App Store drama |
| Career history already in DB | Club×country / league / era are **cheap** vs trophy APIs |

| Weakness vs Immaculate Footy | Mitigation |
|------------------------------|------------|
| Smaller public brand | Niche leagues + TR/DE localization + share cards |
| Nationality coverage historically sparse | Backfill ongoing (~75%+ with ISO codes); gate World XI on coverage |
| No FBref-depth stats | Skip “50+ PL goals” until paid ingest; win on career graph |

### 0.4 Product Director recommendation

**Do next (P1):** Club × Nationality (**World XI**) + Themed Week LiveOps + home “Coming modes” teaser.  
**Do not next:** Connections clone, Transfer Guess clone, or a 5th bottom-nav tab — they dilute the grid brand and burn engineering on loops we don’t own.

**Marketing narrative:**

> *CrossBall isn’t another “guess the player” quiz. It’s the football intersection board — clubs, countries, eras — one grid, infinite axes.*

ASO / store keywords to expand when World XI ships: `football grid`, `soccer puzzle`, `immaculate`, `football IQ`, `club nationality`.

---

## Part 1 — Prioritized mode backlog

### Scoring methodology

| Metric | Scale | Meaning |
|--------|-------|---------|
| **Engagement** | 1–10 | Retention, replay, shareability |
| **Data cost** | 1–5 | 1 = existing DB · 3 = derived · 5 = new paid ingest |
| **Arch fit** | High / Med / Low | Reuse of grid + validate-answer + search |
| **Premium fit** | Free · Freemium · Premium | Placement without pay-to-win |
| **Priority** | P0–P4 | P0 shipped · P1 next · P4 revenue+data |

**Composite (sort):** `Engagement × 2 − Data cost + (Arch High = 2, Med = 1, Low = 0)`

### Backlog table

| Rank | Mode | Axis / modifier | Eng | Data | Arch | Premium | Pri | Cx | Notes |
|------|------|-----------------|-----|------|------|---------|-----|----|-------|
| 1 | **Daily Classic** | Club × Club | 10 | 1 | High | Free | P0 ✅ | — | Core UTC daily |
| 2 | **Friend Challenge** | Club × Club | 9 | 1 | High | Free | P0 ✅ | M | Async viral |
| 3 | **Practice** | Club × Club | 8 | 1 | High | Freemium | P0 ✅ | M | Quota · 4×4 premium |
| 4 | **Club × Nationality** | Club × Country | 9 | 1 | High | Freemium | **P1** | L | **First new axis** — Part 2 |
| 5 | **Themed Week** | Club × Club + LiveOps | 8 | 1 | High | Freemium | **P1** | M | PL week, derbi, WC nations |
| 6 | **Timeline Training** | Club × Club + career | 7 | 1 | High | Premium | P0 ✅ | L | Shipped |
| 7 | **Blitz** | Any grid + 60s | 8 | 1 | High | Freemium | P2 | M | Session modifier only |
| 8 | **Club × League** | Club × “played in L” | 8 | 2 | High | Freemium | P2 | L | Career → club → league |
| 9 | **Mystery Row** | Hidden axis labels | 7 | 1 | High | Freemium | P2 | M | Modifier |
| 10 | **Nationality × Nationality** | Country × Country | 6 | 1 | Med | Free | P3 | M | “Played for both nations?” needs caps data — **defer** unless we define as dual-citizenship only |
| 11 | **Club × Era** | Club × decade | 7 | 2 | High | Premium | P3 | L | Career date filter |
| 12 | **Teammate Bridge** | Player × Player | 7 | 3 | Med | Freemium | P3 | L | Shared club stint overlap; viral but new UX |
| 13 | **Glory Grid** | Club × Trophy | 9 | 5 | Med | Premium | P4 | XL | Needs `player_honors` |
| 14 | **Reverse Training** | Player → pick axes | 6 | 1 | Med | Free | P3 | M | Onboarding |
| 15 | **Career Path Daily** | Guess player from clubs | 8 | 1 | Low | Freemium | P4 | L | Market-hot but **off-grid**; only if DAU plateaus |

### Recommended build order

```
Now → Soft-launch panel teasers (LiveOps announcements) — Part 3
P1  → World XI (Club × Nationality) + Themed Week
P2  → Blitz + Mystery Row (modifiers, cheap)
P2  → Club × League (second axis via puzzle_axes)
P3  → Club × Era · Reverse · Teammate Bridge
P4  → Glory Grid · optional Career Path satellite
```

### Intentionally deferred / excluded

| Idea | Why |
|------|-----|
| Connections-style 16-tile groups | Different product; high content ops cost |
| Manager axis (Guardiola × …) | No manager-stint table |
| Stat axis (50+ PL goals) | Paid stats API |
| Realtime co-op | XL infra; after DAU proof |
| AI trivia quiz | Off-brand |

---

## Part 2 — Club × Nationality product spec

**Codename:** `nationality_grid` / `world_xi`  
**Player-facing:** **World XI** (EN) · **Dünya 11’i** (TR) · **World XI** (DE)  
**Tagline:** *Name players who wore the club **and** fly the flag.*

### 2.1 Positioning

| Dimension | Choice |
|-----------|--------|
| Core fantasy | “Which Brazilians played for Chelsea?” |
| vs Classic | Slightly different skill; broader cultural appeal; same grid chrome |
| Cannibalization | Does **not** replace daily — weekly + practice entry |
| Brand | Row = club badges · Col = flag chips (`CountryFlags`) |

### 2.2 Validation rules

| Layout (v1) | Row | Column | Rule |
|-------------|-----|--------|------|
| **A (recommended)** | Club | Nationality | Senior stint at club **AND** `players.nationality_code = col` |

**Senior stint** — same as classic ([ARCHITECTURE.md](./ARCHITECTURE.md) §5): `is_senior`, not youth/reserve; loans count.

**Nationality (v1):**

- ISO alpha-2 on `players.nationality_code`
- Dual nationality / caps: **out of scope** for v1
- Data gate: prefer nations with ≥ N players in DB; continue nationality backfill from Kaggle/API patches

**Non-rules (v1):** no national-team cap required; no era filter.

```sql
player_played_for_clubs(player_id, row_club_ref)
AND players.nationality_code = col_nationality_code
```

### 2.3 Grid layouts & access

| Variant | Grid | Access | Schedule |
|---------|------|--------|----------|
| World XI Weekly | 3×3 | Free | Monday UTC |
| World XI Practice | 3×3 | Free quota | On-demand |
| World XI Elite | 4×4 | Premium | Unlimited |

**Header sketch:**

```
         🇫🇷 France    🇧🇷 Brazil    🇵🇹 Portugal
[Chelsea]
[Arsenal]
[Real]
```

### 2.4 Difficulty & generation

| Tier | Min answers / cell |
|------|--------------------|
| Easy | 12+ |
| Medium | 6+ |
| Hard | 4+ |
| Legend | 2–3 |

Gates: ≥3 nations; max 1 column per nation; ≥2 leagues in club set; quality ≥ 80; avoid repeat club+nation pairs within 14 days.

### 2.5 Hints

| Hint | World XI |
|------|----------|
| first_letter, position, career_league, retired | Yes |
| nationality | **No** (column already is nationality) |
| career_club | Yes (premium) |

### 2.6 Copy (l10n keys)

| Key | EN | TR | DE |
|-----|----|----|-----|
| `modeWorldXiTitle` | World XI | Dünya 11'i | World XI |
| `modeWorldXiSubtitle` | Club meets country | Kulüp × milliyet | Verein trifft Nation |
| `ruleWorldXi` | Name a player who played for **{club}** and is **{nationality}**. | **{club}**'de oynayan **{nationality}** bir oyuncu yaz. | Nenne einen Spieler, der für **{club}** spielte und **{nationality}** ist. |

### 2.7 Entry points

| Location | Action |
|----------|--------|
| Home card | “World XI — This week” |
| Practice mode chip | World XI |
| LiveOps banner | When `world_xi_week` active |
| **Coming soon panel** | Pre-launch teaser (Part 3) |

No 5th bottom-nav tab in v1.

### 2.8 LiveOps theme examples

| Week | Clubs | Nations |
|------|-------|---------|
| PL diaspora | Top 6 PL | FR, BR, ES, NG, BE, HR |
| Latin link | Real, Barça, Atlético | AR, BR, UY, CO |
| WC hangover | Finalist clubs | WC nations |

Flag: `world_xi_mode` in `liveops_feature_flags` (off until launch).

### 2.9 Monetization

| Surface | Free | Premium |
|---------|------|---------|
| Weekly | 1/week | Same |
| Practice | Quota | Unlimited |
| 4×4 | Locked | Open |
| Ads | On complete | None |

### 2.10 Technical sketch

**Prefer generic axes early** (Appendix A) so League/Era don’t need another one-off table. v1 may still ship `puzzle_col_nationalities` if faster.

```sql
ALTER TYPE puzzle_mode ADD VALUE IF NOT EXISTS 'world_xi';

CREATE TABLE club_nationality_relationships (
  club_id UUID REFERENCES clubs(id),
  nationality_code CHAR(2) NOT NULL,
  valid_player_count INT NOT NULL DEFAULT 0,
  player_ids UUID[] NOT NULL DEFAULT '{}',
  difficulty_score NUMERIC(4,2),
  PRIMARY KEY (club_id, nationality_code)
);
```

| Layer | Work |
|-------|------|
| RPC | `validate_player_club_nationality` |
| Edge | `validate-answer` axis mode; `practice-puzzle` filter; weekly ensure |
| Flutter | `PuzzleMode.worldXi`, `NationalityHeaderCell`, search highlight for club only |
| Pipeline | `refresh_club_nationality_relationships()` post-load |

### 2.11 Rollout & metrics

| Stage | Gate |
|-------|------|
| Alpha | Relationships populated; 10 hand puzzles |
| Beta 5% | Validation error &lt; 0.1% |
| Launch | D7 retention ≥ daily baseline |
| v1.1 | Themed LiveOps weeks |

| Metric (8 weeks) | Target |
|------------------|--------|
| Weekly participation | ≥ 25% DAU |
| Completion | ≥ 60% starters |
| Session time | 4–7 min |
| Share rate | ≥ 8% completions |

### 2.12 Risks

| Risk | Mitigation |
|------|------------|
| Bad nationality data | Patches + coverage gate per nation |
| Too easy (BR×Chelsea) | Legend tier + min answer floors |
| Confusion with Classic | First-open rule banner |
| Sparse graph | Exclude thin nations |

---

## Part 3 — In-app panel: “Yakında / Coming modes”

### 3.1 Why

Marketing wants **anticipation** without shipping unfinished modes. LiveOps already supports `liveops_announcements` + home `LiveOpsAnnouncementBanner` (title, body, CTA, deep link). Use that — no new nav surface.

### 3.2 Placement

| Surface | Content |
|---------|---------|
| Home announcement (priority high) | One rotating “Coming mode” card |
| Community / LiveOps hub (if present) | Static “Roadmap” section listing 2–3 upcoming modes |
| Practice hub empty state | Soft line: “World XI arrives soon” |

**Do not** deep-link to a broken route. CTA = `null` or opens a **read-only info sheet** (`/coming-modes`) until flag on.

### 3.3 Suggested announcement payloads (i18n)

**EN**

| Field | Copy |
|-------|------|
| title | Coming soon: World XI |
| body | Same grid. New axes. Name players who fit the **club and the country**. Weekly free puzzle — stay sharp. |
| button | Learn more |

**TR**

| Field | Copy |
|-------|------|
| title | Yakında: Dünya 11'i |
| body | Aynı ızgara, yeni eksenler. Hem **kulüp** hem **milliyet** uyan oyuncuyu bul. Haftalık ücretsiz bulmaca yolda. |
| button | Daha fazla |

**DE**

| Field | Copy |
|-------|------|
| title | Demnächst: World XI |
| body | Dasselbe Raster, neue Achsen. Spieler, die zu **Verein und Nation** passen. Wöchentliches Rätsel kommt bald. |
| button | Mehr erfahren |

Secondary teaser (rotate after World XI ships): **Themed Week** / **Blitz**.

### 3.4 Ops checklist

- [ ] Insert rows in `liveops_announcements` + `liveops_announcement_i18n` (EN/TR/DE)
- [ ] `starts_at` / `ends_at` window; `priority` above soft-launch noise
- [ ] Feature flag `world_xi_mode` remains **false** until Alpha
- [ ] Analytics: `announcement_impression`, `announcement_cta_tap` via existing LiveOps track
- [ ] When mode ships: swap announcement → “Play World XI” deep link

### 3.5 Optional Flutter sheet (`ComingModesSheet`)

Read-only list driven by remote config JSON (not hardcoded forever):

```json
{
  "modes": [
    {
      "slug": "world_xi",
      "status": "coming_soon",
      "title_key": "modeWorldXiTitle",
      "blurb_key": "modeWorldXiSubtitle",
      "eta": "2026-Q3"
    },
    {
      "slug": "themed_week",
      "status": "coming_soon",
      "eta": "2026-Q3"
    },
    {
      "slug": "blitz",
      "status": "planned",
      "eta": "2026-Q4"
    }
  ]
}
```

Fits LiveOps content rotation / remote config patterns already in ARCHITECTURE.

---

## Part 4 — Planning calendar (indicative)

| Window | Product | Marketing |
|--------|---------|-----------|
| **Now** | Nationality coverage QA; axis design spike | Home “Yakında: Dünya 11’i” announcement |
| **Q3 2026** | World XI Alpha → Beta → Weekly launch | Store screenshot with flags; TR/DE press note |
| **Q3–Q4** | Themed Week (WC / league calendars) | Calendar-tied push + LiveOps events |
| **Q4** | Blitz + Mystery Row | “Hardcore week” campaign |
| **2027 H1** | Club × League; evaluate Glory Grid data budget | Premium story: “more axes” |

---

## Appendix A — Generic axis architecture

```
puzzle_axes (
  puzzle_id UUID,
  axis_index SMALLINT,   -- 0..n row, 100..100+n col
  axis_kind TEXT,        -- club | nationality | league | era | trophy
  ref_id TEXT,           -- club id/slug, ISO, league id, decade, trophy id
  PRIMARY KEY (puzzle_id, axis_index)
)
```

World XI v1 may use `puzzle_col_nationalities` for speed; migrate to `puzzle_axes` when axis #3 ships.

**Search UX rule (all heterogeneous grids):** prioritize axis-matching clubs/labels in `clubs_preview` (already done for club×club cell context).

---

## Appendix B — Shipped vs planned modes

| `puzzle_mode` | Status | Doc |
|---------------|--------|-----|
| `daily` | Shipped | ARCHITECTURE §4 |
| `practice` | Shipped | ARCHITECTURE §15 |
| `challenge` | Shipped | ARCHITECTURE §14 |
| `timeline` | Shipped | migration 024 |
| `world_xi` | **Planned P1** | Part 2 |
| themed / blitz / mystery | Modifiers | Part 1 |
| `club_league` / era / glory | Planned P2–P4 | Part 1 |

---

## Appendix C — Competitor quick reference

| Product | Loop | Takeaway for us |
|---------|------|-----------------|
| Immaculate Footy | Club/stat grid + rarity | Stay grid-first; rarity is table stakes |
| Athletic Connections Soccer | 16 → 4 groups | Don’t clone; steal **calendar marketing** only |
| Football IQ | 11+ daily mini-modes | Catalog ASO works; brand dilution risk — we stay focused |
| Transfer Guess / Career Path | Clue → name player | Optional satellite later; not core |
| Player Pursuit | Clues + H2H | Social H2H after DAU; not before axes |

---

*Next engineering step: `puzzle_axes` or `puzzle_col_nationalities` + `refresh_club_nationality_relationships()` + `NationalityHeaderCell` + LiveOps “coming soon” announcement rows. Reference this doc in Agent mode to implement.*
