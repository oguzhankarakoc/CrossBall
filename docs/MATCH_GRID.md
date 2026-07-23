# Match Grid — Product & Engineering Spec

Branch: `feature/match-grid`  
Status: **Ready to ship** (client + edge + migration; polish included)  
Target release: iOS **1.0.2**

## Summary

Practice sub-mode: 3×3 club grid with a **shuffled tray of the 9 correct players**. Users **drag-and-drop** chips onto cells. Wrong drop **bounces back** (no penalty). No search, no hints.

## Locked decisions

| Topic | Decision |
|-------|----------|
| Name | **Match Grid** |
| Entry | Practice tab card (alongside Classic / Quick Grid / Timeline) |
| Pool | Exactly 9 correct players (no distractors), **shuffled** each session |
| Wrong drop | Bounce back, no score penalty |
| Hints | None |
| Canonical answer | One player id per cell at bank generation |
| Timer | **120s** countdown (same for Quick Grid) |
| Completion | Match Grid–specific score summary → replay requires **rewarded ad** (free) |
| Quota | Practice **unlimited**; free users need rewarded ad for **each new session** (and hints in other modes) |
| Offline | Online required |
| Daily | Unchanged |

## Scoring (soft feedback)

- Reuse Quick Grid–style cell points + remaining-time bonus (120s).
- Practice is non-competitive — no global leaderboard write beyond existing session complete.

## Architecture

```
Practice tab → ?mode=matchGrid
  → practice-puzzle (existing grid)
  → match-grid-bank (9 canonical players for cells)
  → Match Grid UI (DragTarget cells + Draggable tray)
  → validate-answer on successful drop (anti-cheat)
  → complete-session
```

## Practice quota change (all training modes)

- Remove 5/10 hard caps (SQL `practice_daily_limit` → high sentinel / unlimited) — migration `054_practice_unlimited_ad_gate.sql`.
- Free: `needs_ad` before every new session (not only after first).
- Premium: no ads between sessions.
- Hints (Classic/Timeline): still rewarded ad for free (already).

## Client polish (shipped)

- Result copy: `matchGridResultTitle` / perfect vs partial subtitles; **Placed X/Y** instead of hints.
- Haptics: selection on hover, medium on correct drop, heavy on bounce.
- Empty / error: `CrossBallEmptyState` (tray cleared), `CrossBallErrorPanel` (bank load fail).

## Related UX fixes on this branch

- App icon: full-bleed leather icon (no white corner fringe / inset square artifact).
- Search green badge: Daily/Practice/Timeline show cell-relevant highlight; `search-players` marks `is_cell_relevant` when the player validates (competitive only skips ranking boost).
- Faster mode open: skip redundant puzzle-by-id hydrate when cells are valid; parallel daily gates; practice quota TTL + Practice tab prefetch; home warms daily puzzle cache.

## Deploy checklist

```bash
./scripts/run_migrations.sh 054
supabase functions deploy match-grid-bank
supabase functions deploy search-players   # if not already deployed this train
```

## Key files

| Area | Path |
|------|------|
| Spec | `docs/MATCH_GRID.md` (this file) |
| Mode | `PuzzleMode.matchGrid`, Practice tab card, l10n EN/TR/DE |
| Constants | `GameConstants.matchGridDurationSec` (120) |
| Migration | `supabase/migrations/054_practice_unlimited_ad_gate.sql` |
| Edge | `supabase/functions/match-grid-bank/` |
| UI | `lib/features/puzzle/presentation/widgets/match_grid_playfield.dart` |
| API | `lib/features/puzzle/data/match_grid_bank_api.dart` |

## Out of scope (v2)

- Distractors / hard mode
- Offline cache
- Daily Match Grid
