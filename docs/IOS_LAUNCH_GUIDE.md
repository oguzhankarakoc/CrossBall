# CrossBall — iOS Launch Rehberi

**App Store Connect · RevenueCat · AdMob · Push Notifications**

Bu doküman, CrossBall’ı App Store’a göndermek için gereken tüm adımları **sırayla** listeler. Her adımda **senin** yapacağın işler ile **kodda hazır olan** işler ayrılmıştır.

**Hedef kitle:** Geliştirici (Oğuzhan Karakoç)  
**Son güncelleme:** Temmuz 2026  
**CrossBall sürüm:** `1.0.0+21` (App Store — Ready for Distribution / soft launch)

**Semboller**

| Sembol | Anlam |
|--------|--------|
| 👤 **Sen** | App Store Connect, Apple Developer, AdMob, Firebase, Xcode imzalama — sadece sen yapabilirsin |
| ✅ **Kod** | Repoda tamamlandı — ekstra geliştirme gerekmez |

---

## 0. Launch sırası (adım adım)

Aşağıdaki sırayı takip et. Her adım bitince kutuyu işaretle.

---

### Adım 1 — Apple Developer Program

| | |
|---|---|
| 👤 **Sen** | [developer.apple.com](https://developer.apple.com) → **Account** → Developer Program üyeliğini aktif et ($99/yıl). |
| ✅ **Kod** | — |

- [ ] Developer Program aktif

---

### Adım 2 — App ID & Push/IAP yetkileri

| | |
|---|---|
| 👤 **Sen** | [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) → **Identifiers** → **+** → **App IDs** |
| | Description: `CrossBall` |
| | Bundle ID: **`com.crossball.crossball`** (Explicit) |
| | Capabilities: **In-App Purchase** ✅ · **Push Notifications** ✅ |
| ✅ **Kod** | `ios/Runner/Runner.entitlements` — `aps-environment: production` |
| ✅ **Kod** | `ios/Runner/Info.plist` — `UIBackgroundModes: remote-notification` |
| ✅ **Kod** | `ios/Runner.xcodeproj` — entitlements bağlı |

- [ ] App ID oluşturuldu
- [ ] Push + IAP capability işaretli

---

### Adım 3 — APNs Key (uzaktan push için)

| | |
|---|---|
| 👤 **Sen** | Developer Portal → **Keys** → **+** → **Apple Push Notifications service (APNs)** |
| | `.p8` dosyasını indir (bir kez!) — Key ID + Team ID not et |
| | Bu key’i **Adım 8**’de Firebase’e yüklersin |
| ✅ **Kod** | — |

- [ ] APNs Key (.p8) indirildi ve güvenli yerde

---

### Adım 4 — App Store Connect: Yeni uygulama

| | |
|---|---|
| 👤 **Sen** | [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps** → **+** → **New App** |
| | Platform: iOS · Name: **CrossBall** |
| | Bundle ID: **`com.crossball.crossball`** |
| | SKU: `crossball-ios-001` |
| ✅ **Kod** | Bundle ID Xcode ile eşleşiyor: `com.crossball.crossball` |

Detay: [§3 App Store Connect](#3-app-store-connect)

- [ ] App Store Connect’te CrossBall kaydı açıldı

---

### Adım 5 — In-App Purchase (Premium)

| | |
|---|---|
| 👤 **Sen** | App Store Connect → CrossBall → **Monetization** → **In-App Purchases** → **+** |
| | Type: **Non-Consumable** |
| | Product ID: **`crossball_premium`** ← kod ile aynı olmalı |
| | Fiyat tier seç · EN/TR açıklama yaz · Review screenshot yükle |
| 👤 **Sen** | **Users and Access** → **Sandbox** → **Testers** → sandbox Apple ID ekle |
| ✅ **Kod** | `lib/features/premium/premium_service.dart` — StoreKit satın alma |
| ✅ **Kod** | `supabase/functions/verify-premium` — backend doğrulama |
| ✅ **Kod** | `.env.example` → `IAP_ENABLED`, `IAP_PREMIUM_PRODUCT_ID_IOS` |

`.env` production:

```env
IAP_ENABLED=true
IAP_PREMIUM_PRODUCT_ID_IOS=crossball_premium
FORCE_FREE_TIER=false
```

Detay: [§5 In-App Purchase](#5-in-app-purchase--revenuecat)

- [ ] IAP product `crossball_premium` Ready to Submit
- [ ] Sandbox tester oluşturuldu

---

### Adım 6 — AdMob hesabı & reklam birimleri

| | |
|---|---|
| 👤 **Sen** | [admob.google.com](https://admob.google.com) → **Apps** → **Add App** → iOS → **CrossBall** |
| 👤 **Sen** | 3 ad unit oluştur: **Banner**, **Interstitial**, **Rewarded** |
| 👤 **Sen** | Aldığın ID’leri `.env` dosyana yaz (aşağıdaki şablon) |
| 👤 **Sen** | Terminalde: `./scripts/sync_ios_admob_plist.sh` (Info.plist’e App ID yazar) |
| ✅ **Kod** | `lib/features/ads/ads_service.dart` — banner / interstitial / rewarded |
| ✅ **Kod** | `lib/core/ads/tracking_permission_service.dart` — iOS ATT |
| ✅ **Kod** | `lib/main.dart` — ATT → AdMob init sırası |
| ✅ **Kod** | `scripts/sync_ios_admob_plist.sh` |

`.env` production:

```env
ADMOB_ENABLED=true
ADMOB_USE_TEST_ADS=false
ADMOB_IOS_APP_ID=ca-app-pub-XXXXXXXX~YYYYYYYYYY
ADMOB_BANNER_IOS=ca-app-pub-XXXXXXXX/1111111111
ADMOB_INTERSTITIAL_IOS=ca-app-pub-XXXXXXXX/2222222222
ADMOB_REWARDED_IOS=ca-app-pub-XXXXXXXX/3333333333
```

Detay: [§6 AdMob](#6-admob-ios)

- [ ] AdMob App ID alındı
- [ ] 3 ad unit ID `.env`’e yazıldı
- [ ] `sync_ios_admob_plist.sh` çalıştırıldı

---

### Adım 7 — Gizlilik & App Store metadata

| | |
|---|---|
| 👤 **Sen** | Gizlilik politikası URL’si yayınla (web / GitHub Pages) |
| 👤 **Sen** | App Store Connect → **App Privacy** nutrition labels doldur (AdMob, Supabase, PostHog) |
| 👤 **Sen** | Age Rating anketi · Screenshots (6.7" + 6.5") · Description · Keywords |
| 👤 **Sen** | Support URL + Review contact bilgileri |
| ✅ **Kod** | ATT metni: `Info.plist` → `NSUserTrackingUsageDescription` |

Detay: [§3.5–3.6](#35-app-privacy-nutrition-labels)

- [ ] Privacy policy URL canlı
- [ ] App Privacy dolduruldu
- [ ] Screenshots yüklendi

---

### Adım 8 — Firebase & uzaktan push (opsiyonel ama önerilir)

| | |
|---|---|
| 👤 **Sen** | [console.firebase.google.com](https://console.firebase.google.com) → **Add project** → CrossBall |
| 👤 **Sen** | iOS app ekle · Bundle ID: `com.crossball.crossball` |
| 👤 **Sen** | Project Settings → **Cloud Messaging** → APNs **Authentication Key** (.p8) yükle |
| 👤 **Sen** | Project Settings → **General** → iOS/Android app config değerlerini kopyala |
| 👤 **Sen** | `.env` içine Firebase değerlerini yaz · `REMOTE_PUSH_ENABLED=true` |
| 👤 **Sen** | Supabase secrets: `FCM_SERVICE_ACCOUNT_JSON`, `CRON_SECRET` (§9) |
| 👤 **Sen** | `send-streak-reminder` edge function için cron kur |
| ✅ **Kod** | `firebase_core` + `firebase_messaging` paketleri |
| ✅ **Kod** | `lib/core/notifications/remote_push_service.dart` — FCM token → Supabase |
| ✅ **Kod** | `lib/features/notifications/push_notification_service.dart` — yerel + uzaktan |
| ✅ **Kod** | `supabase/functions/register-push-token` + `send-streak-reminder` |
| ✅ **Kod** | `.env.example` — Firebase anahtarları |

`.env` Firebase:

```env
REMOTE_PUSH_ENABLED=true
FIREBASE_PROJECT_ID=crossball-xxxxx
FIREBASE_MESSAGING_SENDER_ID=123456789012
FIREBASE_IOS_API_KEY=AIza...
FIREBASE_IOS_APP_ID=1:123456789012:ios:abcdef
```

Firebase değerlerini **Project Settings → Your apps → SDK setup** ekranından al.

Detay: [§7 Push bildirimleri](#7-push-bildirimleri)

- [ ] Firebase projesi oluşturuldu
- [ ] APNs key Firebase’e yüklendi
- [ ] `.env` Firebase + `REMOTE_PUSH_ENABLED=true`
- [ ] Supabase FCM secrets ayarlandı

> **Not:** Firebase kurmadan da launch yapabilirsin — yerel streak hatırlatıcı (saat 18:00) zaten çalışır.

---

### Adım 9 — Supabase production secrets

| | |
|---|---|
| 👤 **Sen** | Supabase Dashboard → **Project Settings** → **Edge Functions** → Secrets |
| 👤 **Sen** | Edge function deploy: `verify-premium`, `register-push-token`, `send-streak-reminder` |
| ✅ **Kod** | Tüm edge function’lar repoda hazır |

```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set IAP_PREMIUM_PRODUCT_ID=crossball_premium
supabase secrets set IAP_SKIP_VERIFY=false
# FCM HTTP v1 (Firebase → Service accounts → Generate new private key)
./scripts/setup_fcm_push_secrets.sh --service-account /path/to/firebase-adminsdk.json
# veya manuel:
# supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat firebase-adminsdk.json)"
# supabase secrets set CRON_SECRET="$(openssl rand -hex 32)"
supabase functions deploy verify-premium register-push-token send-streak-reminder
```

Detay: [§9 Supabase secrets](#9-supabase-edge-function-secrets)

- [ ] Supabase secrets ayarlandı
- [ ] Edge function’lar deploy edildi

---

### Adım 10 — Production `.env` & Supabase URL

| | |
|---|---|
| 👤 **Sen** | Proje kökünde `.env` dosyasını production değerleriyle doldur |
| 👤 **Sen** | `SUPABASE_URL` + `SUPABASE_ANON_KEY` prod projeden |
| ✅ **Kod** | `.env.example` — tüm anahtar şablonları |
| ✅ **Kod** | `pubspec.yaml` — `.env` asset olarak bundle’a girer |

Detay: [§8 Production `.env`](#8-production-env-checklist)

- [ ] `.env` prod değerleriyle dolu
- [ ] `FORCE_FREE_TIER=false`

---

### Adım 11 — Xcode imzalama & Archive

| | |
|---|---|
| 👤 **Sen** | `ios/Runner.xcworkspace` aç (`.xcodeproj` değil) |
| 👤 **Sen** | Runner → **Signing & Capabilities** → Team seç · Automatic signing ✅ |
| 👤 **Sen** | Capabilities kontrol: Push Notifications görünüyor mu |
| 👤 **Sen** | Gerçek iPhone’da release test (Sandbox IAP + AdMob) |
| 👤 **Sen** | **Product → Archive → Distribute → App Store Connect → Upload** |
| ✅ **Kod** | `DEVELOPMENT_TEAM` + bundle ID projede ayarlı |

```bash
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter build ipa --release
```

- [ ] Archive App Store Connect’e yüklendi
- [ ] Build “Ready” durumuna geldi

---

### Adım 12 — Submit for Review

| | |
|---|---|
| 👤 **Sen** | App Store Connect → Version 1.0.0 → build seç |
| 👤 **Sen** | IAP’yi review ile birlikte gönder |
| 👤 **Sen** | Export compliance · Review notes (anon app, premium optional) |
| 👤 **Sen** | **Submit for Review** |
| ✅ **Kod** | — |

Detay: [§10 Test checklist](#10-gönderim-öncesi-test-checklist)

- [ ] Submit for Review tıklandı

---

### Opsiyonel — RevenueCat (şimdilik gerekmez)

| | |
|---|---|
| 👤 **Sen** | [app.revenuecat.com](https://app.revenuecat.com) → proje + offering kur |
| ✅ **Kod** | **Henüz entegre değil** — native `in_app_purchase` kullanılıyor |
| | Soft launch için Adım 5 (App Store IAP) yeterli. RevenueCat ileride eklenebilir. |

Detay: [§5.2 RevenueCat](#52-revenuecat-kullanmak-istersen-önerilen--uzun-vadede)

---

### Özet tablo

| Adım | Konu | Sen | Kod |
|------|------|-----|-----|
| 1 | Developer Program | ✅ | — |
| 2 | App ID + capabilities | ✅ | ✅ entitlements |
| 3 | APNs Key | ✅ | — |
| 4 | App Store Connect app | ✅ | ✅ bundle ID |
| 5 | IAP Premium | ✅ | ✅ StoreKit |
| 6 | AdMob | ✅ | ✅ ads + ATT + script |
| 7 | Privacy & metadata | ✅ | ✅ ATT metni |
| 8 | Firebase push | ✅ | ✅ FCM client |
| 9 | Supabase secrets | ✅ | ✅ edge fn |
| 10 | `.env` prod | ✅ | ✅ example |
| 11 | Xcode Archive | ✅ | ✅ imza ayarları |
| 12 | Submit review | ✅ | — |

---

## İçindekiler

0. [Launch sırası (adım adım)](#0-launch-sırası-adım-adım) ← **buradan başla**
1. [CrossBall sabitleri](#1-crossball-sabitleri)
2. [Ön koşullar](#2-ön-koşullar)
3. [App Store Connect](#3-app-store-connect)
4. [Apple Developer Portal & Xcode imzalama](#4-apple-developer-portal--xcode-imzalama)
5. [In-App Purchase & RevenueCat](#5-in-app-purchase--revenuecat)
6. [AdMob (iOS)](#6-admob-ios)
7. [Push bildirimleri](#7-push-bildirimleri)
8. [Production `.env` checklist](#8-production-env-checklist)
9. [Supabase edge function secrets](#9-supabase-edge-function-secrets)
10. [Gönderim öncesi test checklist](#10-gönderim-öncesi-test-checklist)
11. [Sık hatalar](#11-sık-hatalar)

---

## 1. CrossBall sabitleri

| Alan | Değer | Kaynak |
|------|-------|--------|
| Uygulama adı | **CrossBall** | `ios/Runner/Info.plist` |
| Bundle ID | **`com.crossball.crossball`** | `ios/Runner.xcodeproj` |
| URL scheme | **`crossball://`** | `Info.plist` → challenge deep link |
| IAP product ID (iOS) | **`crossball_premium`** | `.env.example` |
| IAP tipi | **Non-consumable** (tek seferlik premium) | `premium_service.dart` |
| AdMob App ID (test) | `ca-app-pub-3940256099942544~1458002511` | `Info.plist` — **prod’da değiştir** |
| Minimum iOS | 13.0 | `Podfile` |
| ATT metni | `NSUserTrackingUsageDescription` | `Info.plist` (zaten var) |

**Mevcut kod durumu (önemli):**

| Özellik | Paket / servis | Durum |
|---------|----------------|-------|
| Reklam | `google_mobile_ads` + ATT | Kod hazır, prod ID gerekli |
| IAP | `in_app_purchase` (native StoreKit) | Kod hazır, **RevenueCat yok** |
| Push (yerel) | `flutter_local_notifications` | ✅ Çalışır — saat 18:00 streak hatırlatıcı |
| Push (uzaktan) | `firebase_messaging` + `register-push-token` | ✅ Kod hazır — Firebase `.env` + APNs key gerekir (Adım 8) |
| Analytics | PostHog (opsiyonel) | `.env` ile açılır |

---

## 2. Ön koşullar

- [ ] **Apple Developer Program** üyeliği ($99/yıl) — [developer.apple.com](https://developer.apple.com)
- [ ] **App Store Connect** erişimi (ekran görüntündeki hesap: Oğuzhan Karakoç)
- [ ] Mac + Xcode 15+ (`ios/Runner.xcworkspace` açılır, `.xcodeproj` değil)
- [ ] Flutter SDK kurulu, proje build alıyor
- [ ] Supabase prod projesi + migration’lar uygulanmış
- [ ] **Gizlilik politikası URL’si** (App Store zorunlu) — AdMob + Supabase + PostHog için
- [ ] **Destek URL’si** veya destek e-postası

---

## 3. App Store Connect

### 3.1 Yeni uygulama oluşturma

App Store Connect → **Apps** → **+** → **New App**

| Alan | CrossBall için |
|------|----------------|
| Platforms | iOS |
| Name | CrossBall |
| Primary Language | English (U.S.) veya Turkish — birincil dil |
| Bundle ID | `com.crossball.crossball` (Developer Portal’da önce oluşturulmalı) |
| SKU | `crossball-ios-001` (benzersiz, sadece iç kullanım) |
| User Access | Full Access |

> Bundle ID, Xcode’daki `PRODUCT_BUNDLE_IDENTIFIER` ile **birebir aynı** olmalı.

### 3.2 App Information (sol menü)

| Alan | Ne yazılır |
|------|------------|
| **Name** | CrossBall |
| **Subtitle** | Football intersection puzzle (30 karakter max) |
| **Category** | Primary: **Games** → Puzzle · Secondary: **Sports** |
| **Content Rights** | Üçüncü parti içerik yok (resmi logo kullanmıyorsun) |
| **Age Rating** | Anketi doldur — genelde **4+** (şiddet yok) |
| **Privacy Policy URL** | `https://...` (zorunlu) |

### 3.3 Pricing and Availability

- **Price:** Free
- **Availability:** Başlangıçta sadece **Turkey** soft launch veya doğrudan tüm ülkeler
- **Pre-orders:** İsteğe bağlı

### 3.4 In-App Purchases (App Store Connect içinde)

App → **Monetization** → **In-App Purchases** → **+**

| Alan | Değer |
|------|-------|
| Type | **Non-Consumable** |
| Reference Name | CrossBall Premium |
| Product ID | **`crossball_premium`** ← kod ile aynı |
| Price | Tier seç (ör. Tier 10 ≈ ₺99 / $9.99) |

**Localization (en + tr):**

| Dil | Display Name | Description |
|-----|--------------|-------------|
| EN | CrossBall Premium | Unlimited practice, 4×4 grid, no ads, timeline mode, premium stats. |
| TR | CrossBall Premium | Sınırsız antrenman, 4×4 grid, reklamsız, timeline modu, premium istatistikler. |

- [ ] **Review screenshot** yükle (Premium ekranından)
- [ ] Durum: **Ready to Submit** (ilk app review ile birlikte gönderilir)

### 3.5 App Privacy (Nutrition Labels)

App → **App Privacy** → **Get Started**

CrossBall’ın topladığı veriler:

| Veri | Toplanıyor mu | Amaç | Üçüncü parti |
|------|---------------|------|--------------|
| User ID (anon UUID) | Evet | App functionality | Supabase |
| Product interaction | Evet | Analytics | PostHog (açıksa) |
| Advertising data | Evet (ATT izni ile) | Advertising | Google AdMob |
| Crash data | Evet (açıksa) | App functionality | — |
| Purchase history | Evet | App functionality | Apple |

AdMob kullanıyorsan **“Data Used to Track You”** bölümünde **Device ID** işaretle.

### 3.6 Version 1.0.0 — App Store sekmesi

**Screenshots (zorunlu):**

| Cihaz | Boyut | Adet |
|-------|-------|------|
| iPhone 6.7" | 1290 × 2796 | min 3 |
| iPhone 6.5" | 1284 × 2778 | min 3 |
| iPad (opsiyonel) | 2048 × 2732 | — |

Önerilen ekranlar: Home, Daily puzzle grid, Sonuç ekranı, Premium, Leaderboard.

**Promotional Text** (170 karakter, güncellenebilir):
> Name footballers who played for both clubs. Daily puzzle, streaks, and club mastery.

**Description:** Oyun mekaniği, günlük puzzle, challenge, practice, premium özellikler.

**Keywords:** football, soccer, puzzle, quiz, clubs, players, intersection, trivia

**Support URL:** Web sitesi veya GitHub Pages  
**Marketing URL:** Opsiyonel

**Build:** Xcode’dan Archive → Upload sonrası burada görünür (§4.4).

**App Review Information:**

| Alan | Öneri |
|------|-------|
| Contact | E-posta + telefon |
| Demo account | Gerekmez (anon login) |
| Notes | “Anonymous-first app. Premium is optional non-consumable IAP. Ads use test mode disabled in production.” |

**Export Compliance:** HTTPS kullanıyorsun → genelde “No” (yalnızca standart şifreleme).

---

## 4. Apple Developer Portal & Xcode imzalama

### 4.1 Identifiers

[developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Identifiers** → **+**

| Alan | Değer |
|------|-------|
| Type | App IDs |
| Description | CrossBall |
| Bundle ID | Explicit: `com.crossball.crossball` |

**Capabilities işaretle:**

| Capability | Ne için |
|------------|---------|
| **In-App Purchase** | Premium satın alma |
| **Push Notifications** | Uzaktan push (FCM/APNs) |
| **Associated Domains** | İleride universal link (opsiyonel) |

### 4.2 APNs Key (push için)

**Keys** → **+** → **Apple Push Notifications service (APNs)**

- Key indir (`.p8`) — **bir kez indirilir**, sakla
- Key ID ve Team ID not et → Firebase’e yüklenecek (§7.3)

### 4.3 Xcode signing

1. `ios/Runner.xcworkspace` aç
2. **Runner** target → **Signing & Capabilities**
3. **Team:** Oğuzhan Karakoç (Personal Team veya Organization)
4. **Bundle Identifier:** `com.crossball.crossball`
5. **Automatically manage signing:** ✅
6. **+ Capability** ekle:
   - Push Notifications
   - In-App Purchase (genelde otomatik)

### 4.4 Archive & Upload

```bash
cd /path/to/CrossBall
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter build ipa --release
```

Veya Xcode: **Product → Archive → Distribute App → App Store Connect → Upload**

Upload sonrası App Store Connect’te build 5–30 dk içinde **Processing** → **Ready** olur.

### 4.5 Info.plist production kontrolü

`ios/Runner/Info.plist` içinde:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>  <!-- GERÇEK AdMob App ID -->
```

Test ID ile store’a gönderme — review reddedilebilir veya gelir sıfır kalır.

---

## 5. In-App Purchase & RevenueCat

### 5.1 Mevcut durum: Native StoreKit

CrossBall şu an **`in_app_purchase`** paketini kullanıyor (`lib/features/premium/premium_service.dart`). RevenueCat SDK **henüz entegre değil**.

**Native IAP ile yapman gerekenler (RevenueCat olmadan):**

1. App Store Connect’te product oluştur (§3.4) — **`crossball_premium`**
2. Sandbox tester ekle: App Store Connect → **Users and Access** → **Sandbox** → **Testers**
3. `.env` production:

```env
IAP_ENABLED=true
IAP_PREMIUM_PRODUCT_ID_IOS=crossball_premium
FORCE_FREE_TIER=false
```

4. Supabase `verify-premium` edge function secret’ları (§9)
5. Cihazda Sandbox Apple ID ile test et

**Backend uyarısı:** `verify-premium` şu an tam Apple receipt validation yapmıyor (`IAP_STRICT_VERIFY` açıksa 501 döner). Store öncesi ya RevenueCat ya da Apple App Store Server API entegrasyonu planla.

---

### 5.2 RevenueCat kullanmak istersen (önerilen — uzun vadede)

RevenueCat, receipt doğrulama, restore, analytics ve A/B test için App Store Connect’in üzerine bir katman ekler. Bookmark’ında RC var — kullanmak mantıklı ama **kod değişikliği gerekir** (`purchases_flutter` paketi).

#### 5.2.1 RevenueCat Dashboard

1. [app.revenuecat.com](https://app.revenuecat.com) → **New Project** → `CrossBall`
2. **Apps** → **+ New App** → **Apple App Store**
3. **App name:** CrossBall iOS
4. **Bundle ID:** `com.crossball.crossball`
5. **Shared Secret / In-App Purchase Key:**
   - App Store Connect → **Users and Access** → **Integrations** → **In-App Purchase**
   - **Generate In-App Purchase Key** (`.p8`) → RevenueCat’e yükle
   - Veya eski **App-Specific Shared Secret** (legacy)

#### 5.2.2 Product & Entitlement

| RevenueCat | Değer |
|------------|-------|
| **Entitlement** | `premium` |
| **Product** | `crossball_premium` (App Store product ID ile eşle) |
| **Offering** | `default` |
| **Package** | `$rc_lifetime` veya `lifetime` → `crossball_premium` |

#### 5.2.3 API Keys

RevenueCat → **Project Settings** → **API Keys**

| Key | Kullanım |
|-----|----------|
| **Public iOS API Key** | Flutter client `.env` → `REVENUECAT_IOS_API_KEY` |
| **Secret API Key** | Supabase backend webhook / server doğrulama — **client’a koyma** |

#### 5.2.4 RevenueCat → Supabase webhook (opsiyonel)

Premium durumunu server-side güncellemek için:

1. RevenueCat → **Integrations** → **Webhooks**
2. URL: Supabase edge function (yeni: `revenuecat-webhook`)
3. Event: `INITIAL_PURCHASE`, `RENEWAL` (subscription yoksa sadece `INITIAL_PURCHASE`), `CANCELLATION`

Webhook `set_user_premium` RPC çağırır — client’a güvenilmez.

#### 5.2.5 Flutter entegrasyonu (yapılacak iş)

```yaml
# pubspec.yaml
dependencies:
  purchases_flutter: ^8.x
```

```env
# .env
IAP_ENABLED=true
REVENUECAT_IOS_API_KEY=appl_xxxxxxxxxxxx
```

`PremiumServiceImpl` → RevenueCat `Purchases.purchasePackage()` ile değiştirilir. Detay: [RevenueCat Flutter docs](https://www.revenuecat.com/docs/getting-started/installation/flutter).

#### 5.2.6 RevenueCat vs Native — karar tablosu

| | Native `in_app_purchase` | RevenueCat |
|--|---------------------------|------------|
| Kurulum hızı | Hızlı (kod hazır) | Orta (SDK + dashboard) |
| Receipt validation | Kendin yazmalısın | Otomatik |
| Restore | Manuel | Otomatik |
| Analytics | Yok | Dashboard + charts |
| Maliyet | Ücretsiz | $0–$2.5k MTR |

**Soft launch:** Native IAP yeterli. **Ciddi gelir hedefi:** RevenueCat’e geç.

---

## 6. AdMob (iOS)

### 6.1 Google AdMob hesabı

1. [admob.google.com](https://admob.google.com) → Google hesabınla giriş
2. **Apps** → **Add App**
3. **Platform:** iOS
4. **App store listing:** Hayır (henüz yayında değilse “No” — sonra bağla)
5. **App name:** CrossBall

AdMob sana bir **App ID** verir:

```
ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
```

### 6.2 Ad Unit oluşturma

CrossBall üç reklam tipi kullanıyor (`lib/features/ads/ads_service.dart`):

| Tip | `.env` key | Kullanım yeri |
|-----|------------|---------------|
| **Banner** | `ADMOB_BANNER_IOS` | Home, stats, result |
| **Interstitial** | `ADMOB_INTERSTITIAL_IOS` | Puzzle tamamlanınca |
| **Rewarded** | `ADMOB_REWARDED_IOS` | Hint / practice unlock |

Her biri için AdMob → **Ad units** → **Add ad unit**:

1. Banner → isim: `crossball_ios_banner`
2. Interstitial → `crossball_ios_interstitial`
3. Rewarded → `crossball_ios_rewarded`

Her birinin **Ad unit ID**’si:

```
ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN
```

### 6.3 CrossBall `.env` production

```env
ADMOB_ENABLED=true
ADMOB_USE_TEST_ADS=false

ADMOB_IOS_APP_ID=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
ADMOB_BANNER_IOS=ca-app-pub-XXXXXXXXXXXXXXXX/1111111111
ADMOB_INTERSTITIAL_IOS=ca-app-pub-XXXXXXXXXXXXXXXX/2222222222
ADMOB_REWARDED_IOS=ca-app-pub-XXXXXXXXXXXXXXXX/3333333333
```

### 6.4 Info.plist güncelle

`ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
```

`GADApplicationIdentifier` = **App ID** (`~` ile biten), ad unit ID değil.

### 6.5 iOS App Tracking Transparency (ATT)

CrossBall ATT’yi zaten istiyor (`lib/core/ads/tracking_permission_service.dart`):

- `NSUserTrackingUsageDescription` Info.plist’te var
- AdMob init öncesi `requestTrackingPermissionIfNeeded()` çağrılıyor (`main.dart`)

**App Store Connect Privacy:** Tracking için AdMob + ATT açıklaması tutarlı olmalı.

### 6.6 AdMob ↔ App Store Connect bağlama

App yayına alındıktan sonra:

1. AdMob → App → **App settings** → **Link to store** → Apple App Store → CrossBall (`id6787542181`)
2. **app-ads.txt** doğrulama (önerilir):

```text
google.com, pub-5852330455572459, DIRECT, f08c47fec0942fa0
```

- Dosya hostname **kökünde** olmalı: `https://oguzhankarakoc.github.io/app-ads.txt`  
  (repo: [oguzhankarakoc.github.io](https://github.com/oguzhankarakoc/oguzhankarakoc.github.io); kopya: `docs/app-ads.txt`)
- App Store **Marketing URL** sürüm sayfasında (`1.0.0` → Marketing URL). Yayındaki sürümde alan kilitli olabilir — yeni sürüm gerekir.
- AdMob hostname’e bakar; Marketing URL `.../CrossBall/` olsa da kök `app-ads.txt` yeterlidir.
- Doğrulama sonrası AdMob’da **Güncellemeleri kontrol edin** (crawl 1–24 saat sürebilir).

### 6.7 Test vs production

| Ortam | `ADMOB_USE_TEST_ADS` | Davranış |
|-------|----------------------|----------|
| Geliştirme | `true` | Google test reklamları |
| TestFlight | `false` + gerçek ID | Gerçek reklamlar (düşük fill) |
| Production | `false` | Gerçek reklamlar |

> TestFlight’ta test reklamı göstermek review için OK; production’da test ID **kullanma**.

### 6.8 Premium kullanıcı

`isPremiumProvider == true` → banner gizlenir, interstitial atlanır (`PremiumAdsSync` in `main.dart`).

---

## 7. Push bildirimleri

CrossBall’da push **iki katmanlı**:

| Katman | Teknoloji | Durum |
|--------|-----------|-------|
| **Yerel hatırlatıcı** | `flutter_local_notifications` | ✅ Çalışır — her gün 18:00 streak |
| **Uzaktan push** | FCM + APNs + `register-push-token` | ⚠️ Backend hazır, client FCM eksik |

Settings ekranında toggle var (`push_opt_in` → Supabase `users` tablosu).

---

### 7.1 Katman 1 — Yerel bildirim (şimdi çalışır)

Ekstra kurulum **gerekmez**. Uygulama açılınca:

1. iOS izin dialog’u (`requestPermissions`)
2. Saat 18:00’de “Keep your streak alive” local notification

**Test:** Settings → Push açık → uygulamayı kapat → 18:00’i bekle veya kodda saati değiştir.

**App Store:** Local notification için özel capability gerekmez; izin runtime’da istenir.

---

### 7.2 Katman 2 — Uzaktan push (FCM + APNs)

Server tarafı hazır:

- `user_push_tokens` tablosu (migration 020)
- `register-push-token` edge function
- `send-streak-reminder` edge function (cron ile çağrılır)

Client tarafında **`firebase_messaging` paketi henüz yok** — token `registerToken()` hiç çağrılmıyor.

#### Adım A — Apple Developer

1. App ID’de **Push Notifications** capability (§4.1)
2. **APNs Key** oluştur (`.p8`) (§4.2)
3. Xcode → Runner → **Push Notifications** capability (§4.3)

#### Adım B — Firebase projesi

1. [console.firebase.google.com](https://console.firebase.google.com) → **Add project** → `CrossBall`
2. **Add app** → iOS
3. **Bundle ID:** `com.crossball.crossball`
4. `GoogleService-Info.plist` indir → `ios/Runner/GoogleService-Info.plist` (Xcode’a ekle)

#### Adım C — Firebase ↔ APNs

Firebase → Project Settings → **Cloud Messaging** → **Apple app configuration**

| Alan | Değer |
|------|-------|
| APNs Authentication Key | `.p8` dosyası yükle |
| Key ID | Apple’dan |
| Team ID | Apple Developer Team ID |

#### Adım D — Flutter client

✅ **Kodda tamamlandı:**

- `lib/core/notifications/remote_push_service.dart` — FCM init + token kayıt
- `lib/features/notifications/push_notification_service.dart` — yerel + uzaktan birleşik
- `.env` → `REMOTE_PUSH_ENABLED=true` + Firebase anahtarları (Adım 8)

Senin yapman gereken: Firebase console + `.env` değerleri (Adım 8).

#### Adım E — Supabase secrets

1. Firebase Console → **Project settings** → **Service accounts** → **Generate new private key** (JSON)
2. Google Cloud Console → **Firebase Cloud Messaging API** → Enable
3. Supabase’e secret kaydet ve deploy et:

```bash
./scripts/setup_fcm_push_secrets.sh --service-account /path/to/firebase-adminsdk.json
```

`send-streak-reminder` fonksiyonunu cron ile tetikle (günde 1, UTC 15:00 ≈ TR 18:00):

```bash
# Supabase Dashboard → Edge Functions → send-streak-reminder → Schedules
# Cron: 0 15 * * *
# Header: Authorization: Bearer $CRON_SECRET
```

> **Not:** `send-streak-reminder` **FCM HTTP v1** kullanır (`FCM_SERVICE_ACCOUNT_JSON`). Legacy `FCM_SERVER_KEY` artık desteklenmez.

#### Adım F — iOS background (opsiyonel)

Sessiz push / arka plan için Xcode → **Background Modes** → Remote notifications.

---

### 7.3 Push test checklist

- [ ] İlk açılışta bildirim izni dialog’u geliyor
- [ ] Settings toggle kapalı → local schedule iptal
- [ ] Settings toggle açık → 18:00 local bildirim
- [ ] (FCM sonrası) Token Supabase `user_push_tokens`’a yazılıyor
- [ ] (FCM sonrası) `send-streak-reminder` test çağrısı push iletiyor
- [ ] Premium / opt-out kullanıcıya push gitmiyor

---

## 8. Production `.env` checklist

Proje kökünde `.env` (commit etme):

```env
# Supabase (zorunlu)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...

# Analytics (opsiyonel)
ANALYTICS_ENABLED=true
POSTHOG_API_KEY=phc_...
POSTHOG_HOST=https://eu.i.posthog.com

# IAP
IAP_ENABLED=true
IAP_PREMIUM_PRODUCT_ID_IOS=crossball_premium
FORCE_FREE_TIER=false

# AdMob (production ID'ler)
ADMOB_ENABLED=true
ADMOB_USE_TEST_ADS=false
ADMOB_IOS_APP_ID=ca-app-pub-XXXX~YYYY
ADMOB_BANNER_IOS=ca-app-pub-XXXX/...
ADMOB_INTERSTITIAL_IOS=ca-app-pub-XXXX/...
ADMOB_REWARDED_IOS=ca-app-pub-XXXX/...

# RevenueCat (sadece entegre edersen)
# REVENUECAT_IOS_API_KEY=appl_...
```

**Xcode release build:** `.env` dosyası `pubspec.yaml` assets’te — Archive öncesi prod değerlerinin doğru olduğunu kontrol et.

---

## 9. Supabase edge function secrets

Supabase Dashboard → **Project Settings** → **Edge Functions** → Secrets:

| Secret | Fonksiyon | Açıklama |
|--------|-----------|----------|
| `SUPABASE_SERVICE_ROLE_KEY` | Otomatik | — |
| `IAP_PREMIUM_PRODUCT_ID` | `verify-premium` | `crossball_premium` |
| `IAP_SKIP_VERIFY` | `verify-premium` | Prod: `false` |
| `IAP_STRICT_VERIFY` | `verify-premium` | Apple API bağlanana kadar `false` |
| `FCM_SERVICE_ACCOUNT_JSON` | `send-streak-reminder` | Firebase service account JSON (FCM HTTP v1) |
| `CRON_SECRET` | `send-streak-reminder` | Cron auth header |

Deploy:

```bash
supabase functions deploy verify-premium register-push-token send-streak-reminder
```

---

## 10. Gönderim öncesi test checklist

### App Store / Xcode

- [ ] Release build gerçek cihazda açılıyor
- [ ] Daily puzzle Supabase’ten geliyor (demo fallback yok)
- [ ] Deep link `crossball://challenge/abc` çalışıyor
- [ ] ATT dialog AdMob’dan önce gösteriliyor
- [ ] Premium satın alma Sandbox’ta tamamlanıyor
- [ ] Restore purchases çalışıyor
- [ ] Premium sonrası reklamlar kayboluyor

### AdMob

- [ ] Production ad unit ID’ler `.env` + Info.plist’te
- [ ] Test ads kapalı (`ADMOB_USE_TEST_ADS=false`)
- [ ] Banner home + result’ta görünüyor (free user)
- [ ] Interstitial puzzle complete sonrası (free user)

### Push

- [ ] Local streak reminder 18:00 (opt-in)
- [ ] Opt-out Settings’ten kapanıyor

### Legal / Store

- [ ] Privacy policy URL canlı
- [ ] App Privacy nutrition labels dolduruldu
- [ ] Age rating tamamlandı
- [ ] Screenshots yüklendi
- [ ] IAP “Ready to Submit”

---

## 11. Sık hatalar

| Hata | Çözüm |
|------|-------|
| `Module 'app_tracking_transparency' not found` | `cd ios && pod install --repo-update` |
| AdMob “Invalid application ID” | Info.plist `GADApplicationIdentifier` = App ID (`~`), unit ID değil |
| IAP product not found | Product ID App Store Connect ile `.env` aynı mı; Sandbox tester mı |
| Build Processing stuck | Xcode upload log; versiyon/build numarası artır (`1.0.0+2`) |
| ATT gösterilmiyor | `ADMOB_ENABLED=true` ve gerçek iOS cihaz (simulator sınırlı) |
| Push token kaydedilmiyor | `REMOTE_PUSH_ENABLED=true` mi? Firebase `.env` dolu mu? APNs key Firebase’de mi? |
| Premium bypass | Client `is_premium` yazamaz — server `verify-premium` kullan |

---

*CrossBall kod referansları: `lib/main.dart`, `lib/core/notifications/remote_push_service.dart`, `lib/features/ads/ads_service.dart`, `lib/features/premium/premium_service.dart`, `lib/features/notifications/push_notification_service.dart`, `scripts/sync_ios_admob_plist.sh`, `supabase/functions/verify-premium`, `supabase/functions/register-push-token`, `supabase/functions/send-streak-reminder`.*
