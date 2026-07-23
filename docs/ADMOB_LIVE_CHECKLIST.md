# AdMob live ads — console checklist (iOS)

After shipping **1.0.0+22** (ads init + SKAdNetwork fix).

## AdMob (required)

1. **Apps → CrossBall (iOS) → App settings**
   - Store linked to App Store (`id6787542181`)
   - Click **Check for updates** on `app-ads.txt` until verified  
     Live file: https://oguzhankarakoc.github.io/app-ads.txt

2. **Ad units** (must match production `.env` / shipped binary)
   - Banner: `…/6941613171`
   - Interstitial: `…/5854646222`
   - Rewarded: `…/8548419873`
   - Status = **Active**, format matches (Rewarded ≠ Interstitial)

3. **Policy center / App approval**
   - Resolve “Review required” if still shown
   - Payments → country, tax, account (earnings won’t pay out without this)

4. **Test devices** (optional while debugging)
   - AdMob → Settings → Test devices → add your iPhone IDFA  
   - Or keep production IDs and wait for real fill after +22

## Firebase (optional for ads; needed for push/analytics)

Ads do **not** require Firebase. If you use the CrossBall Firebase project:

1. **Project settings → Your apps → iOS**
   - Bundle ID = `com.crossball.crossball`
   - `GoogleService-Info.plist` already in the app

2. **Cloud Messaging**
   - APNs key/cert uploaded (for remote push only)
   - Not required for AdMob revenue

3. Do **not** create a second AdMob app from Firebase unless you intentionally migrate; keep the existing AdMob App ID  
   `ca-app-pub-5852330455572459~2455573255`

## After upload

1. Upload IPA **1.0.0 (22)** to App Store Connect → submit or phased release  
2. On a free account: Practice → “Watch ad” — fullscreen should open, or SnackBar if inventory empty  
3. AdMob → **Apps → Ad units →** check Requests / Match rate after ~24h
