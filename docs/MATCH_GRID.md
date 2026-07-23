# Match Grid — Product & Engineering Spec

Branch: `feature/match-grid`  
Status: Implementing MVP

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
| Completion | Score summary → replay requires **rewarded ad** (free) |
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

- Remove 5/10 hard caps (SQL `practice_daily_limit` → high sentinel / unlimited).
- Free: `needs_ad` before every new session (not only after first).
- Premium: no ads between sessions.
- Hints (Classic/Timeline): still rewarded ad for free (already).

## Files (MVP)

- `docs/MATCH_GRID.md` (this file)
- `PuzzleMode.matchGrid`, Practice tab card, l10n
- `GameConstants.matchGridDurationSec` / Quick Grid → 120
- Migration: unlimited practice + always-ad for free
- Edge: `match-grid-bank`
- UI: `match_grid_board.dart` + puzzle screen branch

## Out of scope (v2)

- Distractors / hard mode
- Offline cache
- Daily Match Grid
