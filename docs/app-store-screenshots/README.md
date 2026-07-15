# CrossBall — App Store Screenshots

Marketing screenshots for **App Store Connect** (iPhone + iPad).

## Sizes

| Device | Folder | Resolution | App Store tab |
|--------|--------|------------|---------------|
| iPhone 6.7" | `iphone/` | 1290 × 2796 | iPhone → 6.7" or 6.5" (auto-scales) |
| iPad 12.9" | `ipad/` | 2048 × 2732 | iPad → 12.9" |

## Files (upload in this order)

1. `01_connect_clubs.png` — Hook: grid + clubs
2. `02_find_the_link.png` — How to play: search + hints
3. `03_prove_football_iq.png` — Reward: score + rarity
4. `04_daily_challenge.png` — Retention: daily + streak
5. `05_weekly_leaderboard.png` — Social: weekly board

**Guideline 4.1(a):** Screenshots use **fictional** club codes and player names only (no real clubs, leagues, or footballers). Do not upload older assets that showed BAR/RMA/LIV/Modrić-style labels.

**IAP review screenshot:** `iap_review/crossball_premium_review.png` — upload under the In-App Purchase’s App Review Information (required to submit `crossball_premium`).

See also: [APP_STORE_RESUBMIT_FIX.md](../APP_STORE_RESUBMIT_FIX.md).

## Regenerate

```bash
python3 scripts/generate_app_store_screenshots.py
```

Requires: `pip install pillow`

## Before final submission

Replace with **real simulator captures** from the app when possible (Settings → same device sizes). These assets are professional **placeholders** with accurate copy and brand colors.

Simulator export:
- iPhone 15 Pro Max → 1290×2796
- iPad Pro 13" (M4) → 2048×2732

Add marketing overlays in Figma if you want device frames.
