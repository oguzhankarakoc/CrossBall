# CrossBall — Engineering Guidelines (AGENTS.md)

Permanent reference for humans and AI agents working on CrossBall.

## Mission

Elevate implementation quality **without** changing gameplay, scoring, puzzle generation, daily logic, friend challenges, premium model, or navigation flow unless usability clearly improves.

## Architecture

- **Feature-first** under `lib/features/<feature>/` with `domain/`, `data/`, `presentation/` where applicable.
- **Core** (`lib/core/`) holds cross-cutting infra: config, network, theme, routing, cache, validation, connectivity.
- **Shared** (`lib/shared/`) holds global providers and reusable UI.
- **Do not** move business rules out of existing domain/notifier code without explicit approval.

```
lib/
├── core/           # Infrastructure only
├── features/       # Product features
├── shared/
│   ├── components/ # Atomic UI (AppButton, AppScreenBody, …)
│   ├── providers/  # Global Riverpod wiring
│   └── widgets/    # Composite design-system widgets (CrossBall*)
└── l10n/
```

## State Management

- **Riverpod 2.x** — keep current approach; no migration to other frameworks.
- Repositories are `Provider`; remote data is `FutureProvider`; game session uses `StateNotifierProvider`.
- Inject dependencies via providers (`apiHttpClientProvider`, repository providers).
- Invalidate providers for retry — never mutate server state from widgets directly.

## Networking

- **Single HTTP client:** `ApiHttpClient` (`lib/core/network/api_http_client.dart`).
- **Single base URL:** `ApiConfig.functionsBaseUrl` from `AppConfig.supabaseUrl`.
- **Environment:** `APP_ENV` in `.env` → `development` | `staging` | `production`.
- Map failures with `ApiExceptionParser` → `AppFailure`.
- Repositories must not instantiate raw `http.Client()` for new code; migrate gradually.
- Debug logging only in `kDebugMode`.
- Timeouts: connect 15s, receive 30s; retries: 1 dev / 2 prod for transient errors.

## Error Handling

- Never show raw exceptions or stack traces to users.
- Use `AppErrorState`, `CrossBallErrorPanel`, `localizedFailureMessage()`.
- `AppFailure` types: `OfflineFailure`, `TimeoutFailure`, `NetworkFailure`, `ServerFailure`, `MaintenanceFailure`, `AuthFailure`, `ValidationFailure`, `NotFoundFailure`.
- Non-critical feeds (activity, facts) may degrade gracefully with `throwOnError: false`.

## Design System

Consume tokens — never hardcode:

| Token | File |
|-------|------|
| Spacing, radius, elevation, duration, typography | `app_tokens.dart` |
| Colors | `app_colors.dart` → `CrossBallColors` extension, `context.cb` |
| Icons | `app_icons.dart` |
| Animations / shadows | `app_animations.dart` |
| Themes | `app_theme.dart` + `theme_resolver.dart` |

### Components

- New atomic UI → `lib/shared/components/`.
- Composite CrossBall-branded blocks → `lib/shared/widgets/crossball_ui.dart`.
- Screens use `AppScreenBody` for SafeArea + pitch background.

## Responsive Layout

- Use `context.responsive` / `ResponsiveContent` (`app_breakpoints.dart`).
- Avoid fixed widths; prefer `Expanded`, `Flexible`, `LayoutBuilder`, `maxContentWidth`.
- Support compact phones through large tablets.

## Safe Area

- Shell tabs: `MainShellScaffold` wraps body with `SafeArea(bottom: false)`.
- Full screens: `AppScreenBody` with explicit edge flags.
- Bottom nav + banner ads live in `bottomNavigationBar` — never overlap gesture bar.
- Pushed routes must include top SafeArea (notch / Dynamic Island).

## Theme

- User prefs: system, light pitch, light classic, dark stadium, dark gold.
- All colors from `ThemeExtension<CrossBallColors>` — no inline `Color(0x…)`.
- Light = mint pitch surfaces; dark = stadium graphite + lime accents.

## Localization

- ARB files: `app_en.arb`, `app_tr.arb`, `app_de.arb`.
- Run `flutter gen-l10n` after string changes.
- First launch follows device language; user override via settings (no restart).
- Error strings live in l10n — map via `localizedFailureMessage`.

## Validation

- Central helpers: `lib/core/validation/validators.dart` (`AppValidators`).
- Nickname: 3–20 chars, `^[\p{L}\p{N}._-]+$` — matches settings + server.

## Offline & Connectivity

- `ConnectivityService` + `isOnlineProvider` for network awareness.
- Show `AppOfflineState` when offline; allow retry.
- `OfflineSyncService` remains authoritative for queued actions.

## Loading UX

- Boot: `_BootScreen` + `AppLoading` until onboarding profile resolves.
- Feature loads: prefer `AppListSkeleton` / `AppStatsSkeleton` for lists and stats; `AppLoading` for full-page.
- Puzzle load: prefer `AppPuzzleSkeleton` over a lone full-screen spinner.
- Home entry only after `onboardingCompleteProvider` succeeds.

## Career data

- Prefer structured sources + reconcile — never scrape Google SERPs.
- Soft-launch / transfer-window fix: `python3 -m pipeline career-truth-pass` (+ `--load`).
- See `docs/CAREER_TRUTH_PASS.md` and `data_pipeline/README.md`.

## Premium

- **Current:** single non-consumable IAP via `in_app_purchase` + `verify-premium` Edge Function.
- No RevenueCat — not needed for one-time premium unlock (no subscriptions or consumables).
- `isPremiumProvider` is the single client truth; never duplicate entitlement checks in widgets.

## Performance

- Prefer `const` constructors.
- Avoid rebuilding large trees — split `ConsumerWidget` scopes.
- Profile `PuzzleGameNotifier` changes carefully — hot path.
- Cache images and puzzle payloads via existing `OfflineCache`.

## Security

- Secrets only in `.env` (gitignored); never commit keys.
- `flutter_secure_storage` for sensitive local data.
- Scores validated server-side; client anti-cheat tracker stays enabled.
- Validate JSON casts; fail gracefully.

## Accessibility

- Minimum touch targets 44×44 logical pixels.
- `Semantics` on error panels, avatars, nav items.
- Support dynamic text via theme text styles (no fixed font sizes in widgets).
- `AppAvatar` includes screen-reader labels.

## Testing

- Unit tests for validators, parsers, pure domain logic.
- Run `flutter test` before PR.
- Do not add trivial widget tests that only pump `MaterialApp`.

## Do's

- Extend existing patterns.
- Small focused diffs.
- Wire `AppFailure` for new network code.
- Document non-obvious business rules in code comments only when needed.

## Don'ts

- Don't rewrite puzzle engine, scoring, or daily rollout logic.
- Don't change gameplay UX without product approval.
- Don't add new icon packages — use `AppIcons` / Material Icons.
- Don't hardcode API URLs or colors.
- Don't commit `.env` or API secrets.

## Commands

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

## Environment Variables

| Key | Purpose |
|-----|---------|
| `APP_ENV` | `development` / `staging` / `production` |
| `SUPABASE_URL` | Project URL |
| `SUPABASE_ANON_KEY` | Anon key for Edge Functions |
| `IAP_ENABLED` | Store purchases |
| `ANALYTICS_ENABLED` | PostHog |

---

*CrossBall — connect clubs, prove your football IQ.*
