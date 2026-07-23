# App Store Rejection Fix — CrossBall 1.0.0

**Submission:** `74edcd5b-16b9-4240-b9d4-e0f244497865`

| Date | Build | Result |
|------|-------|--------|
| Jul 14, 2026 | 19 | Rejected — **2.1(b)** + **4.1(a)** |
| Jul 16, 2026 | 20 | Rejected — **2.1(b) only** (4.1a cleared) |
| Jul 22, 2026 | **21** | Submitted with IAP in **Items** (app + `crossball_premium`) → **Ready for Distribution** / live |

Apple ID: `6787542181` · Store URL: `https://apps.apple.com/app/id6787542181`

---

## Root cause (build 20)

IAP product was **Ready to Submit** on Monetization, but the **version submission** only listed the app binary — not `crossball_premium`.

Proof check before Submit: App Review → submission → **Items** must show **2 rows**:
1. `iOS App 1.0.0 (21)`
2. `CrossBall Premium` / `crossball_premium` (In-App Purchase)

If Items = **1** (only the app), Apple will reject 2.1(b) again.

---

## What Apple said (summary)

| Guideline | Problem | Fix owner |
|-----------|---------|-----------|
| **2.1(b)** | App shows Premium / IAP, but IAP was **not in the review submission** | You in App Store Connect + new binary |
| **4.1(a)** | Cleared on Jul 16 review | Keep clean screenshots |

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
This repo is bumped to **`1.0.0+21`** (Apple last reviewed build **20**).

```bash
flutter clean && flutter pub get
flutter build ipa --release
```

Archive / Transporter → upload → select build **21** on the version page.

### 6. Critical — attach IAP **before** Submit
1. Version **1.0.0** → scroll to **In-App Purchases and Subscriptions**
2. Click **+** / **Select** → choose **CrossBall Premium** (`crossball_premium`)
3. **Save**
4. Confirm the IAP row is visible on the version page (not only under Monetization)
5. If Apple shows a pink banner blocking IAP+version submit, wait until it clears
6. **Submit / Resubmit to App Review**
7. Open the new submission → verify **Items** includes the IAP

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
- [ ] `crossball_premium` Ready to Submit + screenshot uploaded (1284×2778 OK)  
- [ ] IAP **visible on version 1.0.0** page (not only Monetization list)  
- [ ] Build **21** selected  
- [ ] After Submit: submission **Items** shows app **and** IAP (2 items)  
- [ ] Review notes pasted  
- [ ] Demo: no login required  

---

## App Review reply (paste in ASC)

> Thank you for the follow-up.  
> **2.1(b):** The previous submission included only the app binary. We have now attached the non-consumable IAP `crossball_premium` (CrossBall Premium) to this version, confirmed it appears in the submission items with binary **1.0.0 (21)**, and resubmitted for review. The IAP App Review screenshot and metadata remain complete.  
> Please proceed with review of the app and the IAP together.
