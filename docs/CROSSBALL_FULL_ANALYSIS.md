# CrossBall — Kapsamlı Ürün, Teknik ve UX/UI Analizi

**Versiyon:** 1.0.0+1  
**Tarih:** Temmuz 2026  
**Platform:** iOS & Android (Flutter)  
**Slogan:** *Connect clubs. Prove your football IQ.*

---

## İçindekiler

1. [Yönetici Özeti](#1-yönetici-özeti)
2. [Ürün Vizyonu ve Değer Önerisi](#2-ürün-vizyonu-ve-değer-önerisi)
3. [İş Modeli (Business)](#3-iş-modeli-business)
4. [Oyun Mekanikleri ve Kurallar](#4-oyun-mekanikleri-ve-kurallar)
5. [Kullanıcı Yolculukları](#5-kullanıcı-yolculukları)
6. [Özellik Envanteri](#6-özellik-envanteri)
7. [Teknik Mimari](#7-teknik-mimari)
8. [Backend ve Veri Katmanı](#8-backend-ve-veri-katmanı)
9. [UX/UI Tasarım Sistemi](#9-uxui-tasarım-sistemi)
10. [Monetizasyon ve Reklam Stratejisi](#10-monetizasyon-ve-reklam-stratejisi)
11. [Ekonomi ve İlerleme Sistemi (GEE)](#11-ekonomi-ve-ilerleme-sistemi-gee)
12. [LiveOps Motoru (LOE)](#12-liveops-motoru-loe)
13. [Kimlik, Güvenlik ve Anti-Hile](#13-kimlik-güvenlik-ve-anti-hile)
14. [Çevrimdışı Çalışma ve Senkronizasyon](#14-çevrimdışı-çalışma-ve-senkronizasyon)
15. [Yerelleştirme (L10n)](#15-yerelleştirme-l10n)
16. [Analitik ve Olay Takibi](#16-analitik-ve-olay-takibi)
17. [Test Stratejisi ve Kalite](#17-test-stratejisi-ve-kalite)
18. [Bilinen Boşluklar ve Tutarsızlıklar](#18-bilinen-boşluklar-ve-tutarsızlıklar)
19. [Yol Haritası Önerileri](#19-yol-haritası-önerileri)
20. [Operasyonel Gereksinimler](#20-operasyonel-gereksinimler)

---

## 1. Yönetici Özeti

CrossBall, futbol bilgisini ölçen bir **kavşak bulmaca** (intersection puzzle) mobil uygulamasıdır. Oyuncu 3×3 bir ızgarada satır ve sütun başlıklarındaki iki kulübün kesişimine denk gelen hücreler için, her iki kulüpte de forma giymiş bir futbolcuyu bulur.

Uygulama **production-grade** hedefiyle inşa edilmiştir:

| Boyut | Özet |
|-------|------|
| **İş** | Freemium + reklam + IAP premium; günlük alışkanlık (streak), sosyal meydan okuma (challenge), antrenman modu |
| **Teknik** | Flutter + Riverpod + GoRouter istemci; Supabase PostgreSQL + 17 Edge Function sunucu; Python ETL veri hattı |
| **UX** | Stitch tabanlı "Elite Tactical Grid" tasarım dili; cam efektli paneller, stadyum teması, üç dil desteği |
| **Veri** | ~100 top kulüp, Kaggle/API-Football kariyer geçmişi, sunucu taraflı doğrulama |

**Temel farklılaştırıcılar:**
- Nadir oyuncu seçimi daha yüksek puan (rarity sistemi)
- Sunucu taraflı cevap doğrulama (hile önleme)
- Kalite kapılı otomatik bulmaca üretimi (puzzle generation engine)
- Uzaktan yapılandırılabilir ekonomi ve LiveOps (GEE/LOE)
- Anonim kimlik + sunucu taraflı antrenman kotası (sil-yükle ile sıfırlanmaz)

---

## 2. Ürün Vizyonu ve Değer Önerisi

### 2.1 Problem

Futbol bilgi oyunları genelde statik soru-cevap formatındadır. CrossBall, **dinamik ızgara**, **gerçek kariyer verisi** ve **rekabetçi puanlama** ile günlük alışkanlık yaratan bir deneyim sunar.

### 2.2 Hedef Kullanıcı

- Futbol takipçisi, trivia meraklısı
- Günlük kısa oturumlar (3–10 dk) arayan mobil oyuncu
- Arkadaşlarıyla skor karşılaştırmak isteyen sosyal oyuncu

### 2.3 Temel Döngü (Core Loop)

```
Ana ekran → Bulmaca seç (Günlük / Antrenman / Challenge)
         → Hücre seç → Oyuncu ara → Cevap gönder
         → Puan + nadirlik geri bildirimi
         → Tüm hücreler dolunca oturum tamamla
         → Sonuç ekranı → XP/streak güncelle → Reklam (moda göre)
         → Ana ekrana dön veya yeni oturum
```

### 2.4 Duygusal Tasarım Hedefi

Tasarım dili **"Elite Tactical Grid"** — taktik savaş odası / stadyum atmosferi:
- Karanlık zemin, yeşil saha tonları, elektrik limonu CTA
- Cam efektli (glassmorphism) paneller
- Futbol IQ'sunu kanıtlama hissi (trophy, streak, rating)

---

## 3. İş Modeli (Business)

### 3.1 Gelir Akışları

| Akış | Açıklama | Durum |
|------|----------|-------|
| **Rewarded Video** | İpucu ve antrenman kilidi açma | Aktif (AdMob) |
| **Interstitial** | Günlük/challenge tamamlama sonrası | Aktif |
| **Banner** | Ana ekran, istatistik, sonuç ekranı | Aktif |
| **IAP Premium** | `crossball_premium` tek seferlik/abonelik | Aktif (demo modu mevcut) |
| **Push (gelecek)** | Hatırlatma, etkinlik bildirimleri | Altyapı hazır, FCM yok |

### 3.2 Freemium Katmanları

| Özellik | Ücretsiz | Premium |
|---------|----------|---------|
| Günlük bulmaca | ✅ | ✅ |
| Friend Challenge | ✅ | ✅ |
| Antrenman / gün | **5 oturum** | **10 oturum** |
| Antrenman reklamı | 2. oturumdan itibaren rewarded ad | Reklamsız |
| İpucu (6 tip) | Rewarded ad (career club hariç) | Tüm ipuçları reklamsız |
| İstatistik — nadirlik dağılımı | 🔒 Kilitli | ✅ |
| Reklamlar | Banner + interstitial + rewarded | Tamamen kapalı |
| 4×4 ızgara | ❌ (dokümante, UI yok) | ❌ (dokümante, UI yok) |

> **Not:** Mevcut istemci sürümünde tüm modlar **3×3** sabittir (`GameConstants.gridSize = 3`). 4×4 premium README ve LiveOps flag'inde dokümante edilmiş ancak UI'da seçici yok.

### 3.3 Antrenman Kotası — İş Kuralları (Sunucu Otoriter)

Migration **020** ile kota artık cihazda değil, **PostgreSQL**'de tutulur:

| Kural | Değer |
|-------|-------|
| Ücretsiz günlük limit | 5 oturum |
| Premium günlük limit | 10 oturum |
| Gün sınırı | Cihaz timezone offset'i (`timezone_offset_minutes`) |
| İlk oturum | Reklam gerekmez |
| 2.–N. oturum (ücretsiz) | Rewarded ad → `grant_ad_unlock` → yeni oturum |
| Oturum başlatma | `assert_practice_can_start` + `consume_practice_ad_unlock` |
| Oturum bitirme | `consume_practice_session` (erken bitirme dahil) |
| Sil-yükle koruması | `user_uuid` (Secure Storage) + sunucu sayacı |

### 3.4 Kullanıcı Kimliği

- **Zorunlu kayıt yok** — anonim `user_uuid` (UUID v4, Flutter Secure Storage)
- **Opsiyonel nickname** — 3–20 karakter, benzersiz, ayarlardan düzenlenir
- Fallback görünen ad: `Player #A1B2` (UUID prefix)
- Premium durumu: IAP + `sync-user` + `FORCE_FREE_TIER` test flag'i

### 3.5 Rekabet ve Sosyal

- **Günlük streak** — alışkanlık ve geri dönüş metriği
- **Friend Challenge** — aynı bulmacada asenkron skor karşılaştırma, 7 gün geçerlilik
- **Rating & Lig** — GEE ile rekabetçi derecelendirme (Bronze → Legend)

### 3.6 Birim Ekonomisi Özeti

| Metrik | Ücretsiz kullanıcı başına günlük potansiyel reklam |
|--------|-----------------------------------------------------|
| Antrenman rewarded | 0–4 (5 oturumda max 4 reklam kapısı) |
| İpucu rewarded | Sınırsız (kullanıcı talebine bağlı) |
| Interstitial | 1+ (günlük/challenge tamamlama) |
| Banner impression | Ana ekran + stats + result görüntülemeleri |

Premium dönüşüm tetikleyicileri: antrenman limiti, reklam yorgunluğu, kilitli istatistikler, ipucu sürtünmesi.

---

## 4. Oyun Mekanikleri ve Kurallar

### 4.1 Izgara Yapısı

- **3 satır kulübü** × **3 sütun kulübü** = **9 hücre**
- Her hücre: satır kulübü ∩ sütun kulübü kesişiminde geçerli ≥1 oyuncu
- Kulüp başlıkları: `ClubHeaderCell` — badge + kısa isim (Man United, Bayern vb.)
- Hücre durumları: boş (+), seçili (SELECT pulse), çözülmüş (yeşil + oyuncu adı)

### 4.2 Doğrulama Kuralı (Sunucu Otoriter)

Bir cevap **doğru** sayılır ancak ve ancak oyuncunun **her iki kulüpte de senior first-team** forma giymiş olması durumunda:

- ✅ Kiralık (loan) dönemleri dahil
- ❌ Gençlik (youth) takımları hariç
- ❌ B takımı / reserve hariç

**Edge Function:** `validate-answer` → RPC `validate_player_intersection`  
**Kulüp eşdeğerliği:** `club_ids_equivalent_to()` — slug alias desteği (barcelona = fc-barcelona)

### 4.3 Puanlama Sistemi

#### Hücre Puanı

```
rarity_score = max(0, 100 - usage_percentage)

speed_bonus:
  < 30 saniye  → ×1.30
  < 60 saniye  → ×1.15
  < 120 saniye → ×1.00
  ≥ 120 saniye → ×0.85

cell_score = (rarity_score × speed_bonus) - (hücre_hatası × 15)
```

#### Oturum Puanı

```
session_score = Σ cell_scores - (hints_used × 5)
```

#### Challenge Skor Ayarlaması (Sunucu)

```
adjusted = raw_score - (mistakes × 10) - (hints × 5) - (duration_min × 0.5)
```

### 4.4 Nadirlik Katmanları (Rarity)

| Tier | Kullanım % | Renk |
|------|-----------|------|
| Common | >50% | Gri `#9E9E9E` |
| Rare | 25–50% | Mavi `#42A5F5` |
| Epic | 10–25% | Mor `#AB47BC` |
| Legendary | 3–10% | Altın |
| Mythic | ≤3% | Turuncu `#FF6B35` |

Nadirlik, o hücrede o oyuncuyu seçen tüm oyuncuların yüzdesine göre hesaplanır (`rarity_stats` tablosu).

### 4.5 İpucu Sistemi (6 Tip)

| Sıra | Tip | Ücretsiz | Premium |
|------|-----|----------|---------|
| 1 | Milliyet | Rewarded ad | Reklamsız |
| 2 | Pozisyon | Rewarded ad | Reklamsız |
| 3 | İlk harf | Rewarded ad | Reklamsız |
| 4 | Kariyer ligi | Rewarded ad | Reklamsız |
| 5 | Emekli/aktif | Rewarded ad | Reklamsız |
| 6 | Kariyer kulübü | 🔒 Premium only | ✅ |

İpuçları hücre bazında sıralı açılır; chip olarak modalda gösterilir.

### 4.6 Bulmaca Üretim Zorlukları

| Tier | Min. geçerli cevap/hücre |
|------|--------------------------|
| Easy | 15+ |
| Medium | 8+ |
| Hard | 5+ |
| Legend | 3+ |

Günlük bulmaca varsayılan: **hard** tier.  
Kalite kapısı: `quality_score ≥ 85` AND `human_simulation_score ≥ 90` (gevşetilmiş fallback: 60/65).

### 4.7 Oyun Modları Detayı

#### Günlük Challenge
- Günde **1 global bulmaca** (UTC tarih)
- Tamamlayınca interstitial reklam
- Streak ve GEE `daily_completed` eventi tetiklenir
- Challenge oluşturmak için tamamlanmış oturum gerekir

#### Antrenman (Practice)
- Her oturum **farklı kulüp kombinasyonu** (günlük bulmaca asla gösterilmez — migration 018)
- Sunucu kotası + reklam kapısı
- **Antrenmanı Bitir** butonu — erken bitirme, 1 kota tüketir
- Interstitial **yok** (bilinçli iş kararı)
- Sonuç ekranında kalan oturum sayısı + yeni oturum / reklam izle CTA

#### Friend Challenge
- 8 karakterlik kod, 7 gün geçerlilik
- Deep link: `crossball://challenge/{code}`
- Aynı bulmaca, skor karşılaştırma
- Kazanan/kaybeden GEE eventleri

---

## 5. Kullanıcı Yolculukları

### 5.1 İlk Açılış

```
Uygulama başlat
  → AppConfig.load (.env)
  → Supabase.initialize
  → Anonim kullanıcı oluştur/al (Secure Storage UUID)
  → sync-user (timezone, push opt-in, premium)
  → Push stub initialize
  → AdMob + IAP init
  → OfflineSync dinleyici başlat
  → onboardingComplete?
       Hayır → /onboarding (3 sayfa, atlanabilir)
       Evet  → /home
```

### 5.2 Günlük Bulmaca Akışı

```
/home → Hero Card "Daily Challenge" → /puzzle?mode=daily
  → Bulmaca yükle (daily-puzzle API veya cache v6)
  → 9 hücreyi çöz
  → Oturum tamamla (complete-session kuyruğu)
  → Interstitial reklam (premium değilse)
  → Sonuç ekranı: skor, hata, ipucu
  → "Create Challenge" veya "Back to Home"
```

### 5.3 Antrenman Akışı

```
/home → Practice card → /puzzle?mode=practice
  → Sunucudan kota sync (practice-quota GET)
  → Kota doldu? → Limit mesajı + Premium CTA
  → Reklam gerekli? → Ad gate ekranı
  → practice-puzzle API (quota assert + puzzle select)
  → Oyna veya "Antrenmanı Bitir"
  → complete-session → consume_practice_session
  → Sonuç: kalan oturum, yeni oturum (reklam?) veya ana ekran
```

### 5.4 Challenge Akışı

**Oluşturma:**
```
Günlük tamamla → Sonuç ekranı "Create Challenge"
  → /challenge → challenge-create API
  → Link kopyala / paylaş
```

**Katılma:**
```
/challenge (kod gir) veya deep link
  → /puzzle?mode=challenge&id=CODE
  → challenge-get API → aynı bulmaca
  → Oyna → challenge-complete + complete-session
  → ChallengeResultScreen (kazandın/kaybettin/berabere)
```

### 5.5 Premium Dönüşüm Yolculukları

| Tetikleyici | Ekran |
|-------------|-------|
| Ana ekran trophy ikonu | /premium |
| Antrenman limiti | Limit mesajı → Premium |
| Ad gate | "Premium: reklamsız antrenman" linki |
| Stats rarity breakdown | Kilitli kart → Upgrade |
| Practice sonuç | Premium skip ads metni |

### 5.6 Navigasyon Haritası

| Route | Ekran | Query |
|-------|-------|-------|
| `/` | SplashScreen | (kullanılmıyor — boot inline) |
| `/onboarding` | OnboardingScreen | — |
| `/home` | HomeScreen | — |
| `/puzzle` | PuzzleScreen | `mode`, `id` |
| `/challenge` | ChallengeScreen | `id` (opsiyonel) |
| `/stats` | StatsScreen | — |
| `/settings` | SettingsScreen | — |
| `/premium` | PremiumScreen | — |

**Alt navigasyon:** Yalnızca Home'da `CrossBallQuickNav` (Home | Practice | Stats | Settings). Diğer ekranlarda geri butonu veya "Back to Home" CTA.

---

## 6. Özellik Envanteri

### 6.1 Tamamlanmış Özellikler

| Özellik | Modül | Notlar |
|---------|-------|--------|
| Anonim auth | `features/auth` | UUID + sync-user |
| Nickname | `features/settings` | Benzersiz, sunucu doğrulamalı |
| Onboarding | `features/onboarding` | 3 sayfa, skip |
| Günlük bulmaca | `features/puzzle` | Cache + API |
| Antrenman | `features/puzzle` | Sunucu kotası |
| Challenge | `features/challenge` | Async multiplayer |
| Oyuncu arama | `features/search` | Debounced, fuzzy |
| İstatistikler | `features/stats` | Premium rarity gate |
| Ekonomi profili | `features/economy` | XP, level, rating, lig |
| LiveOps | `features/liveops` | Flags, events, announcements |
| Premium IAP | `features/premium` | Demo mod destekli |
| AdMob | `features/ads` | 3 format |
| Tema | `theme_mode_provider` | System / Dark / Light |
| Dil | `locale_provider` | EN / TR / DE |
| Deep link | `deep_link_service` | Challenge URI |
| Offline cache | `core/cache` | Daily puzzle, stats, queue |
| Anti-cheat | `core/utils/anti_cheat_tracker` | Metadata gönderimi |
| Push altyapısı | `features/notifications` | Stub + register-push-token API |

### 6.2 Backend Hazır, İstemci Eksik

| Özellik | Backend | İstemci |
|---------|---------|---------|
| Push bildirimleri | `user_push_tokens`, `register-push-token` | FCM/APNs stub |
| Başarımlar (achievements) | GEE tabloları | Stats'ta gösterilmiyor |
| Görevler (missions) | GEE tabloları | UI yok |
| Sezonlar | GEE tabloları | UI yok |
| 4×4 ızgara | API `grid_size` param | UI seçici yok |
| Leaderboard | LiveOps flag | Ekran yok |
| Tournament | LiveOps flag | Ekran yok |
| Recent/suggested picks | Search API | Modal sadece arama |

### 6.3 Ortam Bayrakları (`.env`)

| Değişken | Etki |
|----------|------|
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` | Backend bağlantısı |
| `FORCE_FREE_TIER=true` | Premium devre dışı (test) |
| `IAP_ENABLED=false` | Demo premium toggle |
| `ADMOB_ENABLED=false` | Reklamlar kapalı |
| `POSTHOG_API_KEY` | Analitik |
| `ADMOB_USE_TEST_ADS` | Test reklam birimleri |

---

## 7. Teknik Mimari

### 7.1 Genel Yapı

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Client                        │
│  Presentation → Domain → Data (Clean Architecture)       │
│  Riverpod State │ GoRouter │ OfflineCache               │
└────────────────────────┬────────────────────────────────┘
                         │ HTTPS (apikey + x-user-uuid)
┌────────────────────────▼────────────────────────────────┐
│              Supabase Edge Functions (Deno)              │
│  Service Role → SECURITY DEFINER RPCs                   │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│              PostgreSQL (Supabase)                       │
│  20 Migration │ RLS │ Materialized Views │ GEE/LOE     │
└────────────────────────┬────────────────────────────────┘
                         ▲
┌────────────────────────┴────────────────────────────────┐
│              Python Data Pipeline                        │
│  Kaggle + API-Football + patches → ETL → refresh MVs    │
└─────────────────────────────────────────────────────────┘
```

### 7.2 İstemci Katmanları

| Katman | Konum | Sorumluluk |
|--------|-------|------------|
| **Presentation** | `features/*/presentation/` | Widget, Screen, Provider |
| **Domain** | `features/*/domain/` | Entity, Repository interface |
| **Data** | `features/*/data/` | API, Repository impl, cache |
| **Core** | `lib/core/` | Config, theme, routing, utils |
| **Shared** | `lib/shared/` | Cross-feature providers, widgets |

### 7.3 State Management (Riverpod)

| Provider | Tip | Amaç |
|----------|-----|------|
| `userProfileProvider` | FutureProvider | Anonim profil |
| `puzzleGameProvider(params)` | StateNotifierProvider.family | Aktif oyun durumu |
| `practiceSessionProvider` | StateNotifierProvider | Sunucu kotası |
| `playerProgressionProvider` | FutureProvider | GEE profili |
| `userStatsProvider` | FutureProvider | Aggregate stats |
| `liveOpsSnapshotProvider` | FutureProvider | Remote config |
| `isPremiumProvider` | Provider | IAP + profil birleşik |
| `featureFlagProvider(slug)` | Provider.family | LOE flag |
| `lastCompletedSessionProvider` | StateProvider | Challenge oluşturma |

**Kalıp:** Repository provider'lar data katmanını enjekte eder; oturum tamamlanınca `playerProgressionProvider` ve `userStatsProvider` invalidate edilir.

### 7.4 Bağımlılıklar (pubspec.yaml)

| Paket | Versiyon | Kullanım |
|-------|----------|----------|
| flutter_riverpod | ^2.6.1 | State |
| go_router | ^14.8.1 | Navigasyon |
| supabase_flutter | ^2.9.0 | Backend client |
| google_mobile_ads | ^6.0.0 | Reklam |
| in_app_purchase | ^3.2.3 | Premium |
| flutter_secure_storage | ^9.2.4 | UUID güvenli depolama |
| connectivity_plus | ^6.1.4 | Offline sync tetikleyici |
| app_links | ^6.4.0 | Deep link |
| google_fonts | ^6.2.1 | Inter typography |

### 7.5 Proje Dizin Yapısı

```
CrossBall/
├── lib/
│   ├── main.dart, app.dart
│   ├── core/          # config, theme, routing, cache, sync, utils
│   ├── shared/        # providers, widgets
│   └── features/      # auth, puzzle, search, challenge, stats,
│                      # economy, liveops, settings, premium, ads,
│                      # practice, notifications, onboarding, home
├── supabase/
│   ├── migrations/    # 001–020
│   └── functions/     # 17 edge function
├── data_pipeline/     # Python ETL
├── design/stitch/     # DESIGN.md + mockup
├── docs/              # ARCHITECTURE, TESTING, bu dosya
├── test/              # 12 test dosyası
└── scripts/           # migrations, ETL, cron
```

---

## 8. Backend ve Veri Katmanı

### 8.1 Edge Functions (17)

| Function | Method | Görev |
|----------|--------|-------|
| `daily-puzzle` | GET | Bugünün bulmacası |
| `practice-puzzle` | GET | Antrenman bulmacası + quota gate |
| `practice-quota` | GET/POST | Kota sorgula / ad unlock |
| `validate-answer` | POST | Cevap doğrulama + rarity |
| `search-players` | GET | Fuzzy oyuncu arama |
| `request-hint` | POST | İpucu üretimi |
| `complete-session` | POST | Oturum finalize + GEE + quota |
| `economy-profile` | GET | XP, level, rating, lig |
| `liveops-config` | GET | Remote config snapshot |
| `challenge-create` | POST | Challenge oluştur |
| `challenge-get` | GET | Challenge + bulmaca getir |
| `challenge-complete` | POST | Skor karşılaştır |
| `sync-user` | POST | Profil upsert |
| `stats` | GET | Kullanıcı istatistikleri |
| `register-push-token` | POST | FCM/APNs token kaydı |
| `puzzle-by-id` | GET | UUID ile bulmaca |
| `generate-puzzle` | POST | Manuel/cron üretim |

### 8.2 Migration Özeti (001–020)

| # | Odak |
|---|------|
| 001 | Core schema: users, clubs, players, puzzles, sessions, RLS |
| 002–006 | Kulüp badge, display name, tema |
| 007, 013 | Slug alias, kulüp birleştirme, validation RPCs |
| 009–015 | Puzzle generation engine, quality gates, graph-aware picking |
| 011 | Game Economy Engine (GEE) |
| 012 | LiveOps Engine (LOE) |
| 016 | Player identity_key (dedup) |
| 017–019 | Practice selection, uniqueness, fast generation |
| 020 | Nickname, practice quota, push tokens |

### 8.3 Veri Hattı (data_pipeline/)

```
Kaggle (EA FC 24 / FIFA 23 SoFIFA)
    ↓
transform → players.csv, clubs.csv
    ↓
Manual patches (career_patches.csv)
    ↓
API-Football sync (transfers, 30-day cache)
    ↓
load.py → upsert clubs, players, career_history
    ↓
refresh_player_club_intersections()
refresh_club_relationships()
```

**Kritik kurallar:**
- ~100 top kulüp, 1990+ senior kariyerler
- Youth/B/reserve hariç; loan dahil
- Paralel sync job çalıştırma (deadlock riski)
- GitHub Actions: günlük API sync, haftalık Kaggle

### 8.4 Puzzle Generation Engine

**Graph:** `club_relationships` — kulüp çiftleri arası geçerli oyuncu sayısı (min 3)

**RPC zinciri:**
1. `pick_valid_puzzle_clubs` — top-12 kulüp havuzundan brute-force kombinasyon
2. `evaluate_puzzle_candidate` — kalite + human simulation skoru
3. `generate_puzzle` — tam pipeline (5000 deneme)
4. `generate_practice_puzzle_fast` — kalite döngüsü atlanır (antrenman)
5. `ensure_daily_puzzle` — günlük yoksa üret
6. `select_practice_puzzle` — kullanıcı bazlı ağırlıklı seçim

**Dedup:** `puzzle_hash` (MD5 sorted club UUIDs), 30 gün tekrar engeli

### 8.5 Temel Tablolar

| Tablo | Rol |
|-------|-----|
| `users` | Anonim kimlik, premium, nickname, timezone |
| `clubs` | Kulüp metadata, badge, display_name |
| `players` | Oyuncu + identity_key + search_vector |
| `player_career_history` | Kariyer dönemleri |
| `player_club_intersections` | MV — kesişim oyuncuları |
| `club_relationships` | Kulüp çifti graph |
| `puzzles` + row/col/cells | Bulmaca yapısı |
| `puzzle_sessions` | Oturum timing, skor, suspicious flag |
| `answers` | Hücre cevapları + rarity |
| `user_stats` | Aggregate gameplay |
| `player_progression` | GEE state |
| `user_daily_practice_usage` | Antrenman kotası |
| `user_push_tokens` | Push token registry |
| `challenge_sessions` | Async challenge |

---

## 9. UX/UI Tasarım Sistemi

### 9.1 Tasarım Dili: Elite Tactical Grid

Kaynak: `design/stitch/DESIGN.md` + `screen.png`

**Marka hissi:** Premium futbol taktik odası — karanlık saha, stadyum ışıkları, cam paneller, elektrik limonu aksiyon rengi.

### 9.2 Renk Paleti

#### Dark Stadium (varsayılan gece teması)

| Token | Hex | Kullanım |
|-------|-----|----------|
| Background | `#121416` | Ana zemin |
| Surface | `#1E2022` | Kartlar |
| Primary | `#A1D494` | Futbol yeşili |
| Lime (CTA) | `#C3F400` | Birincil butonlar |
| Gold | `#E9C349` | Streak, başarı |
| Error | `#E53935` | Hata, bakım |

#### Light Pitch (gündüz teması)

| Token | Hex |
|-------|-----|
| Background | `#F0F7F0` |
| Primary | `#2E7D32` |
| Accent | `#9CCC65` |

Erişim: `context.cb` (`CrossBallColors` ThemeExtension)

### 9.3 Tipografi

- **Font:** Inter (Google Fonts)
- **Ölçek:** displayLg (48/w800) → labelCaps (12/w700)
- **AppBar başlıkları:** UPPERCASE, yeşil, tracked
- **Butonlar:** labelLarge, lime renk

### 9.4 Spacing & Radius

| Token | Değer |
|-------|-------|
| xs / sm / md / lg / xl / xxl | 4 / 8 / 16 / 24 / 32 / 48 px |
| containerMargin | 20 px |
| Radius sm → pill | 8 → 999 px |
| Animasyon fast / medium | 150 / 300 ms |

### 9.5 Bileşen Kütüphanesi

| Bileşen | Dosya | Açıklama |
|---------|-------|----------|
| `PitchBackground` | crossball_ui.dart | Radial gradient + saha çizgileri |
| `CrossBallAppBar` | crossball_ui.dart | Frosted blur bar |
| `CrossBallGlassPanel` | crossball_ui.dart | Cam efektli panel |
| `CrossBallCard` | crossball_ui.dart | Navigasyon satırı |
| `CrossBallHeroCard` | crossball_ui.dart | Günlük bulmaca hero |
| `CrossBallLevelStrip` | crossball_ui.dart | XP progress bar |
| `CrossBallQuickNav` | crossball_ui.dart | Alt 4-tab dock |
| `ClubBadge` | club_badge.dart | Abstract shield (resmi logo yok) |
| `ClubHeaderCell` | club_header_cell.dart | Izgara eksen başlığı |
| `PlayerSearchCard` | player_search_card.dart | Arama sonuç satırı |
| `PuzzleGrid` | puzzle_grid.dart | 3×3 oyun ızgarası |
| `PlayerSearchModal` | player_search_modal.dart | Draggable bottom sheet |

### 9.6 Ekran UX Detayları

#### Ana Ekran (HomeScreen)
- Level strip + XP bar (üst)
- LiveOps duyuru banner (varsa)
- Bakım modu uyarı paneli
- Hero card: günlük bulmaca + streak badge
- Aktif etkinlikler (feature flag)
- Hızlı stat kutuları (XP, streak)
- Community goal progress bar'ları
- Mod kartları: Practice, Challenge, Stats, Settings
- Banner reklam (alt)
- Quick nav dock

#### Bulmaca Ekranı (PuzzleScreen)
- **Loading:** Lime spinner
- **Practice limit:** Mesaj + Premium CTA
- **Ad gate:** Cam panel, günlük ilerleme, reklam izle / premium / ana ekran
- **Oyun:** Timer → Grid → skor/finish bar
- **Practice finish bar:** Skor + "Antrenmanı Bitir" (onay diyaloğu)
- **Hücre tap:** Modal arama → cevap sheet

#### Sonuç Ekranı (PuzzleResultScreen)
- Trophy ikon (lime glow)
- Skor (44px), hata, ipucu istatistikleri
- Practice: kalan oturum + günlük progress
- CTA: Yeni oturum / reklam izle / Challenge oluştur / Ana ekran
- Banner reklam (alt)

#### Ayarlar (SettingsScreen)
- Nickname kartı (dialog editör, validasyon)
- Görünüm seçici (System / Dark / Light)
- Dil seçici (System / EN / TR / DE)
- Versiyon + tagline footer

### 9.7 UX Güçlü Yönler

- Tutarlı pitch background + glass panel dili
- Lime CTA hiyerarşisi net
- Practice ad gate değer önerisi açık (reklam neden gerekli)
- Draggable search modal native his
- Hint progression görsel (chip'ler)
- Streak ve level strip motivasyon

### 9.8 UX İyileştirme Alanları

| Alan | Sorun |
|------|-------|
| **Tutarsız kart stili** | Challenge/LiveOps/Stats lock plain `Card` kullanıyor |
| **Quick nav** | Sadece Home'da; Stats'ta aktif tab highlight yok |
| **Hardcoded İngilizce** | Grid "SELECT", Splash tagline, versiyon string |
| **Hata durumları** | Bazı ekranlarda raw error string |
| **Erişilebilirlik** | Semantics/Tooltip yok; 8px grid yazıları küçük |
| **Kullanılmayan l10n** | recentPicks, popularPicks, suggestedForCell |
| **comingSoon key** | Loading placeholder olarak kullanılıyor (kafa karıştırıcı) |
| **Search modal close** | Header X dekoratif, dismiss bağlı değil |

---

## 10. Monetizasyon ve Reklam Stratejisi

### 10.1 Reklam Yerleşim Matrisi

| Format | Konum | Tetikleyici | Premium |
|--------|-------|-------------|---------|
| Banner | Home alt | Ekran görüntüleme | Gizli |
| Banner | Stats alt | Ekran görüntüleme | Gizli |
| Banner | Result alt | Oturum sonrası | Gizli |
| Interstitial | Tam ekran | Daily/challenge complete | Atlanır |
| Rewarded | Tam ekran | İpucu (free) | Atlanır |
| Rewarded | Tam ekran | Practice unlock | Atlanır |

**Reklam desteklenmeyen ekranlar:** Oyun grid'i, onboarding, premium, settings, challenge form

### 10.2 IAP Premium

- Ürün ID: `crossball_premium` (env ile override)
- `IAP_ENABLED=false` → demo toggle (store olmadan test)
- `PremiumAdsSync` widget: premium değişince ads service güncellenir
- Restore purchases destekli

### 10.3 Gelir Optimizasyonu Notları

- Practice'te interstitial bilinçli olarak **kapalı** — rewarded ad daha yüksek eCPM ve daha az churn
- `interstitialEveryNPractice = 3` sabiti tanımlı ama **kullanılmıyor** (gelecek A/B için)
- Premium dönüşüm hunisi: limit → ad fatigue → stats lock → hint friction

---

## 11. Ekonomi ve İlerleme Sistemi (GEE)

### 11.1 Tasarım Prensibi

Tüm ödül değerleri **sunucu config tablolarında** — istemcide hardcoded XP yok. `economy_config` JSON blob'ları.

### 11.2 Oyuncu Durumu

| Alan | Açıklama |
|------|----------|
| XP / Level | `economy_level_thresholds` eğrisi |
| Competitive Rating | Varsayılan 1000 |
| Lig | Bronze → Legend (rating band) |
| Streak | current / best |
| Rarity counters | rare, legendary, mythic sayıları |
| Achievement points | Backend hesaplar |

### 11.3 XP Kuralları (Seed Config)

| Event | Base XP |
|-------|---------|
| Puzzle complete | 50 |
| Daily complete | +100 |
| Practice complete | 35 |
| Perfect (0 hata, 0 ipucu) | +75 |
| No hints | +20 |
| Fast complete (<3 dk) | +25 |
| Challenge won | +60 rating, +60 XP |
| Challenge lost | +15 XP, -9 rating |

**Premium multiplier:** Tüm çarpanlar **1.0** (fair play)

### 11.4 Rating Formülü

```
delta = base(4) + score×0.012 + (quality-85)×0.02
        - hints×2.5 - mistakes×3 + perfect_bonus(6) + daily_bonus(3)
Clamped: [-18, +18]
```

### 11.5 Streak Milestone XP

3 / 7 / 30 / 100 günlük milestone bonusları (config'den)

---

## 12. LiveOps Motoru (LOE)

### 12.1 Yetenekler

| Bileşen | Açıklama |
|---------|----------|
| `liveops_config` | Key/value remote config |
| `liveops_feature_flags` | Rollout JSON (%, platform, country) |
| `liveops_events` | Zamanlı etkinlikler + i18n |
| `liveops_announcements` | In-app duyurular |
| `liveops_community_goals` | Global metrik hedefleri |
| `liveops_ab_experiments` | A/B test ataması |
| `liveops_content_rotation` | Dönen içerik |

### 12.2 İstemci Kullanımı

- `liveOpsSnapshotProvider` → `liveops-config` GET
- Cache: `cache_liveops_snapshot_v1`
- Failsafe: `LiveOpsDefaults` (bulmaca her zaman oynanabilir)
- Feature flags: `friend_challenges`, `statistics`, `special_events`
- Emergency: `maintenance_mode`, `disable_new_sessions`

### 12.3 Home Ekranı LiveOps UI

- Announcement banner (üst)
- Maintenance panel (kırmızı ikon)
- Active events listesi
- Community goal progress bar'ları

---

## 13. Kimlik, Güvenlik ve Anti-Hile

### 13.1 Kimlik Modeli

```
Cihaz                          Sunucu
──────                         ──────
Secure Storage: user_uuid  →   users.user_uuid (UNIQUE)
SharedPrefs: nickname      →   users.display_name (UNIQUE)
SharedPrefs: premium       →   users.is_premium
Device timezone            →   users.timezone_offset_minutes
Push consent               →   users.push_opt_in
```

### 13.2 Anti-Hile (AntiCheatTracker)

| Flag | Eşik |
|------|------|
| Uzun oturum (3×3) | >40 dakika |
| Uzun oturum (4×4) | >60 dakika |
| Arka plan oranı | >%50 süre |
| İnaktivite | ≥3 dönem × 2 dk |

**Sonuç:** `is_suspicious=true` → GEE ödülü yok, quota consume yok, session status=`suspicious`

### 13.3 Güvenlik Katmanları

- Cevap doğrulama **yalnızca sunucuda** — istemci doğru/yanlış işaretleyemez
- RLS: Public read (clubs, players, puzzles); write service role
- Edge functions SECURITY DEFINER RPC kullanır
- Kulüp badge'leri abstract symbol — resmi logo kullanılmaz (IP güvenliği)

### 13.4 Push Hazırlığı

| Bileşen | Durum |
|---------|-------|
| `user_push_tokens` tablosu | ✅ |
| `upsert_push_token` RPC | ✅ |
| `register-push-token` edge function | ✅ |
| `PushNotificationService` (client) | Stub — FCM bekliyor |
| `push_opt_in` consent | ✅ sync-user |

**Gelecek entegrasyon:** FCM token al → `registerToken()` → backend kayıt

---

## 14. Çevrimdışı Çalışma ve Senkronizasyon

### 14.1 Cache Stratejisi

| Veri | Key / Versiyon | Depolama |
|------|----------------|----------|
| Günlük bulmaca | v6 | SharedPrefs + JSON file |
| User stats | — | SharedPrefs |
| Progression | v1 | SharedPrefs |
| LiveOps | v1 | SharedPrefs |
| Recent picks | max 10 | SharedPrefs |
| Pending sessions | queue | SharedPrefs |

### 14.2 Offline Sync Akışı

```
completeSession() → queuePendingAnswer()
Connectivity restored → OfflineSyncService.flushPendingSessions()
  → POST complete-session
  → Success: cache progression from response
  → Fail: re-queue
```

### 14.3 Demo Mod

Supabase yapılandırılmamışsa:
- 6 ünlü kulüp demo grid (slug ID'ler, UUID değil)
- `_demoValidate` hardcoded oyuncular
- Production'da kullanılmamalı

---

## 15. Yerelleştirme (L10n)

### 15.1 Desteklenen Diller

| Kod | Dil | ARB |
|-----|-----|-----|
| en | English | app_en.arb |
| tr | Türkçe | app_tr.arb |
| de | Deutsch | app_de.arb |

System locale: tr → de → en fallback

### 15.2 Kapsam

- Oyun modları, ipucu metinleri, practice flow, premium, settings, challenge, stats — **tam kapsam**
- Practice quota, ad gate, finish training, nickname — **güncel**

### 15.3 Lokalize Edilmemiş Stringler

| Konum | String |
|-------|--------|
| PuzzleGrid | "SELECT" |
| SplashScreen | "Strategic Football Dashboard" |
| SettingsScreen | "CrossBall v1.0.0" |
| Router errorBuilder | "Route not found" |
| Boot error | "Failed to initialize" |

---

## 16. Analitik ve Olay Takibi

### 16.1 PostHog Entegrasyonu

- `analyticsProvider` → ConsoleAnalytics + PostHog HTTP composite
- `identify(userUuid, traits)` — startup'ta
- Env: `POSTHOG_API_KEY`, `POSTHOG_HOST`

### 16.2 Takip Edilen Olaylar (Örnek)

| Event | Tetikleyici |
|-------|-------------|
| `answer_submitted` | Cevap gönderimi (correct, latency, rarity) |
| `hint_used` | İpucu kullanımı |
| `puzzle_completed` | Oturum tamamlama |
| `practice_session_completed` | Antrenman bitişi |
| `ad_impression` | Reklam gösterimi (placement) |
| `challenge_completed` | Challenge sonucu |
| Onboarding | complete / skipped |

### 16.3 Backend Analytics

- `analytics_events` tablosu (001)
- `economy_events_log` (GEE audit)
- `liveops_analytics_events` (LOE tracking)

---

## 17. Test Stratejisi ve Kalite

### 17.1 Flutter Testleri (12 dosya)

| Dosya | Kapsam |
|-------|--------|
| scoring_test | Puan, hız bonusu, ceza |
| practice_session_test | Kota/ad gate mantığı |
| anti_cheat_test | Metadata, evaluate |
| club_identity_test | Badge mapping |
| club_display_test | Kısa isim çözümleme |
| deep_link_test | Challenge URI parse |
| offline_cache_test | Cache read/write |
| puzzle_grid_test | 9 hücre render |
| player_progression_test | Level math |
| liveops_snapshot_test | Defaults/parse |
| string_normalizer_test | Accent insensitive |
| widget_test | App smoke |

### 17.2 CI Pipeline

- `flutter analyze`
- `flutter test`
- `flutter gen-l10n`
- `data_pipeline` pytest

### 17.3 Test Boşlukları

- Repository integration testleri sınırlı
- Widget E2E daily flow yok
- Edge function contract testleri yok (client tarafında)
- Premium/IAP flow otomasyonu yok

### 17.4 Manuel QA Checklist (docs/TESTING.md)

Onboarding, daily 3×3, search, rarity feedback, timer, ad placement, challenge, l10n, themes

---

## 18. Bilinen Boşluklar ve Tutarsızlıklar

| # | Konu | Detay | Öncelik |
|---|------|-------|---------|
| 1 | 4×4 premium grid | README + LiveOps flag var, client her zaman 3×3 | Orta |
| 2 | Push notifications | Backend hazır, FCM stub | Yüksek (roadmap) |
| 3 | Achievements/Missions UI | GEE tabloları var, ekran yok | Orta |
| 4 | Leaderboard/Tournament | **Shipped** (Phase 1/4) | — |
| 5 | interstitialEveryNPractice | Sabit tanımlı, kullanılmıyor | Düşük |
| 6 | Splash route `/` | Router'da var, initial route değil | Düşük |
| 7 | Recent/suggested picks | **Shipped** (Phase 2) | — |
| 8 | README migration range | **Güncellendi** (001–036) | — |
| 9 | Challenge import style | Bazı edge function'lar eski deno.land import | Deploy riski |
| 10 | Erişilebilirlik | Semantics layer yok | Orta |
| 11 | Hardcoded EN strings | Grid SELECT, splash | Düşük |
| 12 | Mixed card styling | Challenge/LOE plain Card vs Glass | **Mostly fixed** — glass UI unified |

---

## 19. Yol Haritası Önerileri

### Kısa Vade (1–2 sprint)

1. **FCM push entegrasyonu** — stub'ı doldur, günlük hatırlatma
2. **L10n tamamlama** — hardcoded stringleri ARB'ye taşı
3. **Migration 017–020 deploy** — production quota + nickname
4. **Recent picks UI** — search modal'da spoiler-free recent

### Orta Vade (1–2 ay)

5. **Achievements ekranı** — GEE data'sını görselleştir
6. **Leaderboard** — rating bazlı sıralama
7. **4×4 premium grid** — UI seçici + practice-puzzle grid_size
8. **Erişilebilirlik audit** — Semantics, contrast, dynamic type
9. **Challenge/LiveOps glass panel** — UI tutarlılığı

### Uzun Vade

10. **Sezonluk içerik** — GEE seasons + LOE events derin entegrasyon
11. **Sosyal graph** — arkadaş listesi, push challenge davet
12. **A/B test framework** — LOE experiments client-side exposure
13. **Web/PWA** — cross-platform genişleme

---

## 20. Operasyonel Gereksinimler

### 20.1 Deploy Checklist

```bash
# Migrations
./scripts/run_migrations.sh

# Edge functions
supabase functions deploy daily-puzzle practice-puzzle practice-quota
supabase functions deploy validate-answer search-players request-hint
supabase functions deploy complete-session economy-profile liveops-config
supabase functions deploy challenge-create challenge-get challenge-complete
supabase functions deploy sync-user stats register-push-token

# Data pipeline (after ETL)
SELECT refresh_player_club_intersections();
SELECT refresh_club_relationships();

# Career enrichment (weekly GitHub Actions or manual)
CAREER_ENRICH_LOAD=1 ./scripts/run_career_enrichment.sh
```

### 20.2 Ortam Değişkenleri

| Ortam | Gerekli |
|-------|---------|
| Production | SUPABASE_URL, SUPABASE_ANON_KEY, ADMOB keys, IAP product IDs |
| Staging | FORCE_FREE_TIER=true, ADMOB test units |
| Analytics | POSTHOG_API_KEY |

### 20.3 Monitoring Önerileri

| Metrik | Kaynak |
|--------|--------|
| Daily puzzle generation success | Edge function logs |
| Practice quota 429/403 rate | practice-puzzle logs |
| validate-answer latency | Edge function |
| ETL job success | GitHub Actions |
| Crash rate | Firebase Crashlytics (henüz entegre değil) |
| DAU / retention | PostHog |

### 20.4 Troubleshooting (Sık Karşılaşılan)

| Belirti | Çözüm |
|---------|-------|
| Aynı 6 takım her gün | API fail → demo fallback; migration 014–015, cache v6 temizle |
| Geçerli oyuncu yanlış | validate-answer deploy; migration 007, 013 |
| Practice timeout | Migration 019; 3×3 kullan |
| Practice günlük takımlar | Migration 018 deploy |
| Kota sil-yükle ile sıfırlanıyor | Migration 020 + practice-quota deploy |
| deno.land deploy hatası | npm:@supabase/supabase-js@2 import kullan |

---

## Ek: Dosya Referans Haritası

| Konu | Dosya |
|------|-------|
| Uygulama girişi | `lib/main.dart`, `lib/app.dart` |
| Routing | `lib/core/routing/app_router.dart` |
| Oyun sabitleri | `lib/core/constants/game_constants.dart` |
| Puanlama | `lib/core/utils/scoring.dart`, `rarity.dart` |
| Ana ekran | `lib/features/home/presentation/home_screen.dart` |
| Bulmaca | `lib/features/puzzle/presentation/puzzle_screen.dart` |
| Oyun state | `lib/features/puzzle/presentation/puzzle_providers.dart` |
| Antrenman kotası | `lib/shared/providers/practice_session_provider.dart` |
| Premium | `lib/features/premium/premium_service.dart` |
| Reklamlar | `lib/features/ads/ads_service.dart` |
| Auth | `lib/features/auth/data/auth_repository_impl.dart` |
| Offline | `lib/core/cache/offline_cache.dart`, `lib/core/sync/offline_sync_service.dart` |
| Tasarım tokenları | `lib/core/theme/app_tokens.dart`, `design/stitch/DESIGN.md` |
| Mimari doküman | `docs/ARCHITECTURE.md` |
| Test stratejisi | `docs/TESTING.md` |
| Backend | `supabase/README.md`, `supabase/migrations/` |
| Veri hattı | `data_pipeline/README.md`, `scripts/run_career_enrichment.sh` |

---

*Bu doküman CrossBall kod tabanının (v1.2.0, migration 036) tam analizidir. Teknik değişikliklerde güncellenmesi önerilir.*
