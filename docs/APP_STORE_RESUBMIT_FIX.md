# App Store Rejection Fix — CrossBall 1.0.0 (build 19 → 20)

**Submission:** `74edcd5b-16b9-4240-b9d4-e0f244497865`  
**Rejected:** July 14, 2026 — Guidelines **2.1(b)** + **4.1(a)**

---

## What Apple said (summary)

| Guideline | Problem | Fix owner |
|-----------|---------|-----------|
| **2.1(b)** | App shows Premium / IAP, but `crossball_premium` was **not submitted for review** | You in App Store Connect + new binary |
| **4.1(a)** | Store **metadata** looked like real clubs/players without license | Replace App Store screenshots (+ check description) |

Code already implements Premium via native StoreKit (`crossball_premium`). The binary alone cannot fix a missing IAP submission.

---

## A) Fix 2.1(b) — Submit the IAP (required)

### 1. Paid Apps Agreement
App Store Connect → **Agreements, Tax, and Banking** → **Paid Applications** = **Active**.

### 2. Complete product `crossball_premium`
**Monetization → In-App Purchases** → `crossball_premium` (Non-Consumable)

| Field | Value |
|-------|--------|
| Reference Name | CrossBall Premium |
| Product ID | `crossball_premium` (must match app) |
| Price | e.g. Tier ~$9.99 |
| EN Display Name | CrossBall Premium |
| EN Description | Unlock more ad-free training, advanced stats, exclusive themes, and an ad-free experience. One-time purchase. |
| TR Display Name | CrossBall Premium |
| TR Description | Daha fazla reklamsız antrenman, gelişmiş istatistikler, özel temalar ve reklamsız deneyim. Tek seferlik satın alma. |

### 3. IAP Review screenshot (required)
Upload:

`docs/app-store-screenshots/iap_review/crossball_premium_review.png`

(Regenerate with `python3 scripts/generate_app_store_screenshots.py`.)

### 4. Attach IAP to the version
Version **1.0.0** → **In-App Purchases and Subscriptions** → add **`crossball_premium`**.

Status must become **Ready to Submit**, then it goes with the app.

### 5. New binary
This repo is bumped to **`1.0.0+20`** (Apple reviewed build **19**).

```bash
flutter clean && flutter pub get
flutter build ipa --release
```

Archive → upload → select build **20** on the version page.

---

## B) Fix 4.1(a) — Clean metadata (required)

Apple flagged **metadata** (screenshots / listing), not “delete football from the app.”

### Replace App Store screenshots
Use regenerated assets (fictional club codes + fictional player names only):

- `docs/app-store-screenshots/iphone/*.png`
- `docs/app-store-screenshots/ipad/*.png`

Upload all 5 iPhone (+ iPad if you use iPad listing). **Do not** re-upload old shots with BAR / RMA / LIV / Modrić / etc.

### Safe App Store description (EN example)

> CrossBall is a daily football knowledge puzzle.  
> Connect clubs on a 3×3 grid by finding players who fit both axes.  
> Build streaks, climb the weekly board, and train with practice modes.  
> Optional Premium unlocks more ad-free training and extras (one-time).

### Avoid in subtitle / description / keywords / promo text
- Real club names (Barcelona, Liverpool, …)
- League brands (Premier League, UEFA, FIFA, …)
- “Official”, “licensed”, crest close-ups

### Keywords (safe ideas)
`football,soccer,puzzle,daily,trivia,grid,sports,iq,streak,challenge`

### App Review reply (paste in ASC)

> Thank you for the feedback.  
> **2.1(b):** We completed metadata for the non-consumable IAP `crossball_premium`, attached the required App Review screenshot, linked the product to this version, and uploaded a new binary (1.0.0 build 20).  
> **4.1(a):** We replaced App Store screenshots and listing copy so metadata no longer depicts identifiable third-party clubs, players, or leagues. CrossBall is an original puzzle product; in-app club marks are stylized abstracts, not official crests, and we do not claim affiliation.

---

## Checklist before “Submit for Review”

- [ ] Paid Apps agreement Active  
- [ ] `crossball_premium` Ready to Submit + screenshot uploaded  
- [ ] IAP attached to version 1.0.0  
- [ ] New screenshots uploaded (no real clubs/players)  
- [ ] Description/keywords scrubbed  
- [ ] Build **20** selected  
- [ ] Review notes pasted  
- [ ] Demo account / notes if needed (anonymous OK — say “no login required”)

---

## What we changed in the repo

- Regenerated store screenshots without real IP-looking labels  
- Added IAP review screenshot asset  
- Bumped version to `1.0.0+20`  
- This guide
