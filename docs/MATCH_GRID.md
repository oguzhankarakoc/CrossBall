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
| Canonical answer | One player id per cell at bank generation; **drops must match that id** (not any intersection) |
| Bank assignment | Scarcity-first exact cover: fill scarcest cell first; prefer players unique to fewer cells |
| Timer | **120s** countdown (same for Quick Grid) |
| Completion | Match Grid–specific score summary → next free session may need **rewarded ad** (every 2 sessions) |
| Quota | Practice **unlimited**; free users need rewarded ad every **2** sessions |
| Offline | Online required |
| Daily | Unchanged |

## Scoring (soft feedback)

- Reuse Quick Grid–style cell points + remaining-time bonus (120s).
- Practice is non-competitive — no global leaderboard write beyond existing session complete.

## Architecture

```
Practice tab → ?mode=matchGrid
  → practice-puzzle (existing grid)
  → match-grid-bank in parallel with start-session (9 tray players)
  → Match Grid UI (named club headers + DragTarget + Draggable tray)
  → validate-answer on successful drop (anti-cheat)
  → complete-session
```

## Practice quota change (all training modes)

- Soft-cap 9999 (migration `054`).
- Free: `needs_ad` when `completed_today % 2 == 0` and no unlock (migration `055`) — ad on 1st, 3rd, 5th… session.
- Premium: no ads between sessions.
- Hints (Classic/Timeline): still rewarded ad for free (already).

## Client polish

- Club headers always show **short name under crest** (crests are original art, not licensed logos).
- Layout scales to available height/width (no RenderFlex overflow on compact phones).
- Timer starts only when the Match Grid tray is ready.
- Result copy: `matchGridResultTitle` / perfect vs partial; **Placed X/Y** instead of hints.
- Haptics: selection on correct hover, medium on correct drop, heavy once on wrong/rejected release (no hover spam).

## Deploy checklist

```bash
./scripts/run_migrations.sh 055
supabase functions deploy match-grid-bank
```

> **Why scarcity-first:** Stars like Coutinho fit multiple cells (Inter×Liverpool *and* Barça×Liverpool). Naive per-cell random pick can lock him on the less obvious cell and confuse players. Unique / scarce chips are assigned first so multi-club stars go where they’re still needed.

## Key files

| Area | Path |
|------|------|
| Spec | `docs/MATCH_GRID.md` (this file) |
| Mode | `PuzzleMode.matchGrid`, Practice tab card, l10n EN/TR/DE |
| Constants | `GameConstants.matchGridDurationSec` (120), `practiceRewardedAdEveryNSessions` (2) |
| Migration | `supabase/migrations/055_practice_ad_every_two_sessions.sql` |
| Edge | `supabase/functions/match-grid-bank/` |
| UI | `lib/features/puzzle/presentation/widgets/match_grid_playfield.dart` |
| API | `lib/features/puzzle/data/match_grid_bank_api.dart` |

## Out of scope (v2)

- Distractors / hard mode
- Offline cache
- Daily Match Grid
