# CrossBall

**Connect clubs. Prove your football IQ.**

Production-grade football intersection puzzle app for iOS and Android. Name players who played for **both** clubs at each grid intersection.

## Stack

| Layer | Tech |
|-------|------|
| Client | Flutter, Riverpod, GoRouter |
| Backend | Supabase (PostgreSQL, Edge Functions) |
| Data | Python ETL (Kaggle / SoFIFA + API-Football + manual patches + career enrichment) |
| Ads | AdMob (banner, interstitial, rewarded) + iOS ATT |
| Analytics | PostHog (+ client error events) |

## Quick start

```bash
cp .env.example .env          # SUPABASE_URL + SUPABASE_ANON_KEY
flutter pub get
flutter gen-l10n
flutter run
```

**iOS (first build or after new plugins):**

```bash
cd ios && pod install --repo-update && cd ..
# Open ios/Runner.xcworkspace (not .xcodeproj)
```

### Backend setup (first time)

```bash
# 1. Apply SQL migrations (uses DATABASE_URL in data_pipeline/.env)
chmod +x scripts/run_migrations.sh
./scripts/run_migrations.sh

# 2. Deploy edge functions (see supabase/README.md for full list)
supabase link --project-ref YOUR_PROJECT_REF
supabase functions deploy daily-puzzle validate-answer search-players
supabase functions deploy puzzle-by-id request-hint complete-session start-session
supabase functions deploy practice-puzzle practice-quota economy-profile liveops-config
supabase functions deploy challenge-create challenge-get challenge-complete
supabase functions deploy sync-user stats verify-premium register-push-token
supabase functions deploy club-mastery season consume-hint-taste
supabase functions deploy activity-feed player-fact tournament career-timeline
```

See [Supabase Setup](supabase/README.md), [Security model](supabase/SECURITY.md), and [Data Pipeline](data_pipeline/README.md) for details.

**iOS App Store launch:** [IOS_LAUNCH_GUIDE.md](docs/IOS_LAUNCH_GUIDE.md) — App Store Connect, RevenueCat, AdMob, Push.

## Project structure

```
lib/
├── core/           # theme, routing, cache, scoring, anti-cheat, club identity
├── shared/         # providers, reusable widgets (club badges, glass UI, search)
└── features/       # auth, puzzle, search, challenge, stats, economy, social, tournament
assets/clubs/       # optional per-club metadata overrides (manifest.json)
docs/               # architecture, testing, product audit
supabase/           # migrations (001–036), edge functions, SECURITY.md
data_pipeline/      # Python ingest, API-Football sync, career enrichment
scripts/            # migrations, ETL, scheduled sync, career enrichment
test/               # unit + widget tests (60+ tests)
```

## Game modes

| Mode | Grid | Access |
|------|------|--------|
| Daily Challenge | 3×3 | Free |
| Friend Challenge | 3×3 | Free |
| Practice | 3×3 | Free (server quota + ad gate) |
| Practice | 4×4 | Premium |
| Timeline | Career years | Premium feature flag |

## Original Club Identity System

CrossBall uses **legal-safe procedural badges** — never official club logos.

- **105 curated clubs** — colors + abstract symbols (stripes, wings, compass, lion, etc.)
- Unified design language: rounded shield, flat geometry, premium mobile-game aesthetic
- Reusable widgets: `ClubBadge`, `PuzzleClubTile`, `ClubIdentityChip`, `LeaderboardClubIcon`
- Registry: `lib/core/club_identity/` + optional `assets/clubs/{slug}/metadata.json`
- Puzzle headers always show **badge + club name**

## Validation rule

A cell answer is **correct** when the player has senior first-team appearances at **both** the row club and the column club. Youth, reserve, and B-team stints are excluded. Validation runs server-side via the `validate-answer` edge function.

## Themes

| Theme | Description |
|-------|-------------|
| **Light Pitch** | Soft mint background, forest green accents (default) |
| **Light Classic** | Alternate light palette |
| **Dark Stadium** | Pitch graphite + electric lime (default premium night) |
| **Dark Gold** | Dark stadium with gold accent variant |

All themes use brightness-aware typography (headline/title styles adapt for contrast).

## Documentation

- [Architecture](docs/ARCHITECTURE.md) — system design, API contracts, club identity, phases
- [Testing Strategy](docs/TESTING.md) — test pyramid, CI, QA checklist
- [Product Audit](docs/PRODUCT_AUDIT.md) — phased launch roadmap (Phases 0–5)
- [Full Analysis](docs/CROSSBALL_FULL_ANALYSIS.md) — comprehensive TR/EN product reference
- [Phase 0 Security](docs/PHASE0_SECURITY.md) — migration 021 hardening checklist
- [Supabase Security](supabase/SECURITY.md) — RLS lockdown (036), open-source model
- [Supabase Setup](supabase/README.md) — migrations, edge functions, deploy
- [Data Pipeline](data_pipeline/README.md) — Kaggle ETL, API-Football sync, career enrichment

## Development scripts

```bash
./scripts/run_migrations.sh              # apply pending SQL migrations (001–039, idempotent)
./scripts/run_migrations.sh 021 036      # security hardening through RLS lockdown
./scripts/run_migrations.sh --sync-tracking  # backfill crossball_applied_migrations from Supabase CLI
./scripts/run_etl.sh                     # full Kaggle → PostgreSQL pipeline
./scripts/sync_api_football.sh           # API-Football transfers → DB (manual, ~30 teams)
./scripts/run_career_enrichment.sh       # reconcile stale careers + gap report (no DB load)
CAREER_ENRICH_LOAD=1 ./scripts/run_career_enrichment.sh  # same + apply patches to Supabase
./scripts/run_scheduled_sync.sh          # daily sync (used by GitHub Actions)
./scripts/apply_career_patches.sh        # manual patches only
./scripts/run_ios_simulator.sh           # build & run on iOS simulator
flutter test                             # run all tests
flutter analyze lib/
cd data_pipeline && pytest tests/ -q       # pipeline unit tests
```

## Data automation (production)

After pushing to GitHub, add **Actions secrets**: `DATABASE_URL`, `API_FOOTBALL_KEY` (optional: `KAGGLE_USERNAME`, `KAGGLE_KEY`).

| Workflow | Schedule | Purpose |
|----------|----------|---------|
| `data-sync-daily.yml` | Daily 00:00 UTC (03:00 TRT) | Pending migrations → API-Football (30 teams) → light patch load → daily puzzle |
| `data-etl-weekly.yml` | Sunday 08:00 TR | Kaggle bulk + full graph refresh |
| `career-enrichment-weekly.yml` | Saturday 07:00 TR | All mapped teams → reconcile stale stints → `enriched_careers.csv` → DB load |

See [`.github/workflows/README.md`](.github/workflows/README.md) and [Data Pipeline](data_pipeline/README.md).

**Important:** Never run two sync jobs in parallel (local + Actions, or two terminals) — causes DB deadlocks.

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs `flutter analyze`, `flutter test`, and `data_pipeline` pytest on push/PR to `main` and `feature/**`.

## License

Proprietary — CrossBall © 2026
