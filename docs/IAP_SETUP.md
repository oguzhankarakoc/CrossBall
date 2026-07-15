# CrossBall IAP Kurulumu (Native StoreKit)

Kod **`in_app_purchase`** (native StoreKit) kullanır. **RevenueCat şart değil** — soft launch için bu yol yeterli.

> **App Review (2.1b):** Premium UI varken IAP’yi sürüme **bağlayıp** review’a göndermeden binary gönderme.  
> Adım adım: [APP_STORE_RESUBMIT_FIX.md](./APP_STORE_RESUBMIT_FIX.md)

## App Store Connect — `crossball_premium` (Missing Metadata)

Ekran görüntünde ürün **Draft / Missing Metadata**. Şunları doldur:

### 1. Ürün detayı

| Alan | Değer |
|------|-------|
| Type | **Non-Consumable** |
| Product ID | `crossball_premium` (değiştirme) |
| Reference Name | CrossBall Premium |

### 2. Fiyat

**Pricing** → Price Schedule → örn. **Tier 10** (~$9.99 / ~₺399)

### 3. Localization (en + tr)

| Dil | Display Name | Description |
|-----|--------------|-------------|
| English (U.S.) | CrossBall Premium | Unlimited practice, 4×4 grid, no ads, timeline mode, and premium stats. |
| Turkish | CrossBall Premium | Sınırsız antrenman, 4×4 grid, reklamsız, timeline modu ve premium istatistikler. |

### 4. Review screenshot

Premium ekranının ekran görüntüsünü yükle (Review Information).

### 5. Paid Apps Agreement

**Agreements, Tax, and Banking** → **Paid Apps** sözleşmesi **Active** olmalı.

### 6. Sürüme bağlama

İlk IAP, **1.0 sürüm sayfasında** “In-App Purchases” bölümünden seçilip app review ile birlikte gönderilir.

Durum **Ready to Submit** olunca sandbox test çalışır.

---

## Sandbox test (fiziksel cihaz)

1. App Store Connect → **Users and Access** → **Sandbox** → Sandbox Tester oluştur
2. iPhone **Ayarlar → App Store → Sandbox Hesabı** ile giriş (üretim Apple ID değil)
3. `.env`:
   ```
   IAP_ENABLED=true
   IAP_PREMIUM_PRODUCT_ID_IOS=crossball_premium
   ```
4. Xcode **debug** build fiziksel cihazda çalıştır

---

## Xcode StoreKit Configuration (simülatör / offline)

1. `ios/CrossBall.storekit` projede mevcut
2. Xcode → **Product → Scheme → Edit Scheme → Run → Options**
3. **StoreKit Configuration** → `CrossBall.storekit` seç
4. Simülatörde satın alma test edilebilir (App Store Connect metadata gerekmez)

---

## Supabase `verify-premium` secrets

```bash
supabase secrets set IAP_PREMIUM_PRODUCT_ID=crossball_premium
supabase secrets set IAP_SKIP_VERIFY=false
supabase secrets set IAP_STRICT_VERIFY=false
supabase functions deploy verify-premium --no-verify-jwt
```

| Secret | Prod değer | Açıklama |
|--------|------------|----------|
| `IAP_PREMIUM_PRODUCT_ID` | `crossball_premium` | App Store product ID |
| `IAP_SKIP_VERIFY` | `false` | Gerçek receipt ile doğrulama |
| `IAP_STRICT_VERIFY` | `false` | Apple Server API yokken `true` yapma (501 döner) |

Staging’de store olmadan test: client `IAP_ENABLED=false`, server `IAP_SKIP_VERIFY=true`.

---

## RevenueCat — ne zaman?

| | Native (şimdi) | RevenueCat (ileride) |
|--|----------------|----------------------|
| Kod | Hazır | `purchases_flutter` + servis refactor |
| Receipt doğrulama | Basit (hash kaydı) | RC dashboard |
| Restore / analytics | Manuel | RC otomatik |

Gelir ölçeği büyüyünce RevenueCat eklenebilir; şimdilik App Store Connect metadata + sandbox yeterli.

---

## Sorun giderme

| Belirti | Çözüm |
|---------|--------|
| `Missing Metadata` | Yukarıdaki localization + fiyat + screenshot |
| `premiumPurchaseUnavailable` | Product ID eşleşmesi, IAP metadata, sandbox hesabı |
| `verification_failed` | Supabase secrets; receipt boşsa uygulama güncellemesi |
| `storekit_duplicate_product_object` | Uygulamayı yeniden başlat; Restore Purchases |
| `is_premium: false` | `verify-premium` logları; `iap_verifications` tablosu |
