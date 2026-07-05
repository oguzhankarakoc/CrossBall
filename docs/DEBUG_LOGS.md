# CrossBall — Debug Console Logs (Geçici)

**Amaç:** Debug build sırasında Xcode / Flutter console'da hataları hızlı bulmak.  
**Filtre:** Console'da tag ile ara: `[Daily]`, `[Session]`, `[Config]`, `[Auth]`, `[Practice]`, `[Puzzle]`, `[Challenge]`

**Kaldırma:** Tüm loglar `kDebugMode` ile korunur — release build'de çalışmaz. Yine de launch öncesi bu dosyadaki satırları temizlemek istersen aşağıdaki checklist'i kullan.

---

## Merkezi logger

| Dosya | Fonksiyonlar | Tag örnekleri |
|-------|--------------|---------------|
| `lib/core/debug/crossball_debug_log.dart` | `cbDebug`, `cbDebugError`, `cbDebugConfigSnapshot`, `cbDebugHttpResponse` | Config, Daily, Session, Auth, Puzzle, Challenge |
| `lib/core/debug/practice_debug_log.dart` | `practiceDebug`, `practiceDebugError` → `[Practice]` wrapper | Practice |

---

## Log noktaları (dosya bazlı)

### Startup & config

| Dosya | Tag | Ne loglanır |
|-------|-----|-------------|
| `lib/main.dart` | `Config` | `.env` snapshot, Supabase init OK/fail |
| `lib/core/debug/crossball_debug_log.dart` | `Config` | `cbDebugConfigSnapshot()` — supabaseConfigured, host, IAP, AdMob, Firebase |

### Auth

| Dosya | Tag | Ne loglanır |
|-------|-----|-------------|
| `lib/features/auth/data/auth_remote_data_source.dart` | `Auth` | syncUser POST, OK, fail (status + error body) |
| `lib/features/auth/data/auth_repository_impl.dart` | `Auth` | Remote sync fail → local profile fallback |

### Günlük bulmaca (Daily) — bağlantı hatası burada görünür

| Dosya | Tag | Ne loglanır |
|-------|-----|-------------|
| `lib/features/home/presentation/home_screen.dart` | `Daily` | Ana ekrandan daily açılışı |
| `lib/features/puzzle/data/puzzle_repository_impl.dart` | `Daily` | `getDailyPuzzle` cache hit/miss, invalid payload, fetch OK/fail |
| `lib/features/puzzle/data/puzzle_repository_impl.dart` | `Daily` | `fetchDailyPuzzle` HTTP GET, status, body preview, timeout |
| `lib/features/puzzle/presentation/puzzle_providers.dart` | `Daily` | `loadPuzzle` start/success/fail, session create, UI error key |

### Oturum (Session)

| Dosya | Tag | Ne loglanır |
|-------|-----|-------------|
| `lib/features/puzzle/data/puzzle_repository_impl.dart` | `Session` | `startSession` request/response, timeout, local UUID fallback |
| `lib/features/puzzle/presentation/puzzle_providers.dart` | `Daily` / `Challenge` | Session create adımı |

### Antrenman (Practice)

| Dosya | Tag | Ne loglanır |
|-------|-----|-------------|
| `lib/features/practice/data/practice_quota_api.dart` | `Practice` | fetchQuota GET + response |
| `lib/shared/providers/practice_session_provider.dart` | `Practice` | syncQuota start/OK/fail |
| `lib/features/puzzle/data/puzzle_repository_impl.dart` | `Practice` | fetchPracticePuzzle (mevcut) |
| `lib/features/puzzle/presentation/puzzle_providers.dart` | `Practice` | Practice gate, load success/fail |

### UI hata gösterimi

| Dosya | Tag | Ne loglanır |
|-------|-----|-------------|
| `lib/features/puzzle/presentation/puzzle_screen.dart` | `Puzzle` | Error state UI'ya yansıdığında error key |
| `lib/features/puzzle/presentation/puzzle_providers.dart` | `Daily` / `Practice` / `Challenge` | `loadPuzzle UI error key` |

---

## Günlük mod hata ayıklama rehberi

Console'da şu sırayı takip et:

```
1. [Config] startup snapshot → supabaseConfigured: true olmalı
2. [Config] Supabase.initialize OK
3. [Daily] home → open daily puzzle
4. [Daily] loadPuzzle start
5. [Daily] getDailyPuzzle / fetchDailyPuzzle HTTP response
6. [Daily] daily puzzle loaded VEYA ERROR
7. [Session] startSession request/response
8. [Puzzle] UI showing error → puzzle_load_failed
```

### Sık kök nedenler

| Log mesajı | Muhtemel neden |
|------------|----------------|
| `supabaseConfigured: false` | `.env` cihaz build'ine girmiyor — `pubspec.yaml` assets + Xcode Copy Bundle Resources |
| `Supabase skipped` | `SUPABASE_URL` / `SUPABASE_ANON_KEY` boş |
| `Daily puzzle network error` | İnternet, yanlış URL, SSL, simulator ağ |
| `Daily puzzle unavailable (404/500)` | Edge function deploy edilmemiş veya DB'de günlük bulmaca yok |
| `Invalid daily puzzle payload` | API slug ID döndürüyor; UUID bekleniyor |
| `start-session failed` | Migration 021+ deploy edilmemiş veya session RPC hatası |
| `using demo puzzle` | Supabase client null — init başarısız |

---

## Launch öncesi kaldırma checklist

- [ ] `lib/core/debug/crossball_debug_log.dart` — dosyayı sil veya boş stub bırak
- [ ] `lib/core/debug/practice_debug_log.dart` — sil
- [ ] `lib/main.dart` — `cbDebug*` import ve çağrıları
- [ ] `lib/features/puzzle/data/puzzle_repository_impl.dart` — tüm `cbDebug*` satırları
- [ ] `lib/features/puzzle/presentation/puzzle_providers.dart` — tüm `cbDebug*` + `_debugTagForMode`
- [ ] `lib/features/auth/data/auth_remote_data_source.dart` — `cbDebug*` satırları
- [ ] `lib/features/auth/data/auth_repository_impl.dart` — sync fail log
- [ ] `lib/features/home/presentation/home_screen.dart` — daily tap log
- [ ] `lib/features/practice/data/practice_quota_api.dart` — quota logları
- [ ] `lib/shared/providers/practice_session_provider.dart` — syncQuota logları
- [ ] `lib/features/puzzle/presentation/puzzle_screen.dart` — `ref.listenManual` error listener
- [ ] Bu dosyayı sil: `docs/DEBUG_LOGS.md`

**Hızlı arama:** `grep -r "cbDebug\|practiceDebug\|crossball_debug_log\|practice_debug_log" lib/`

---

*Oluşturulma: Temmuz 2026 — debug session için geçici.*
