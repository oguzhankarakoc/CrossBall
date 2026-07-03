# CrossBall

**Connect clubs. Prove your football IQ.**

Production-grade football intersection puzzle app for iOS and Android. Name players who played for **both** clubs at each grid intersection.

## Stack

| Layer | Tech |
|-------|------|
| Client | Flutter, Riverpod, GoRouter |
| Backend | Supabase (PostgreSQL, Edge Functions) |
| Data | Python ETL (Kaggle / SoFIFA) |
| Ads | AdMob (banner, interstitial, rewarded) |
| Analytics | PostHog |

## Quick start

```bash
cp .env.example .env          # SUPABASE_URL + SUPABASE_ANON_KEY
flutter pub get
flutter gen-l10n
flutter run
```

### Backend setup (first time)

```bash
# 1. Apply SQL migrations (uses DATABASE_URL in data_pipeline/.env)
chmod +x scripts/run_migrations.sh
./scripts/run_migrations.sh

# 2. Deploy edge functions
supabase link --project-ref YOUR_PROJECT_REF
supabase functions deploy daily-puzzle validate-answer search-players
supabase functions deploy puzzle-by-id request-hint complete-session
supabase functions deploy challenge-create challenge-get challenge-complete
supabase functions deploy sync-user stats
```

See [Supabase Setup](supabase/README.md) and [Data Pipeline](data_pipeline/README.md) for details.

## Project structure

```
lib/
├── core/           # theme, routing, cache, scoring, anti-cheat, club identity
├── shared/         # providers, reusable widgets (club badges, search cards)
└── features/       # auth, puzzle, search, challenge, stats, ads, premium
docs/               # architecture, testing strategy
supabase/           # migrations (001–008), edge functions
data_pipeline/      # Python ingest pipeline + pytest
scripts/            # migrations, ETL, iOS simulator, GitHub push
test/               # unit + widget tests (28 tests)
```

## Game modes

| Mode | Grid | Access |
|------|------|--------|
| Daily Challenge | 3×3 | Free |
| Friend Challenge | 3×3 | Free |
| Practice | 3×3 | Free (limited) |
| Practice | 4×4 | Premium |

## Validation rule

A cell answer is **correct** when the player has senior first-team appearances at **both** the row club and the column club. Youth, reserve, and B-team stints are excluded. Validation runs server-side via the `validate-answer` edge function.

## Themes

- **Light Pitch** — off-white pitch background, gold accents (default)
- **Dark Stadium** — dark green pitch, gold accents

## Documentation

- [Architecture](docs/ARCHITECTURE.md) — system design, API contracts, validation
- [Testing Strategy](docs/TESTING.md) — test pyramid, CI, QA checklist
- [Supabase Setup](supabase/README.md) — migrations, edge functions, deploy
- [Data Pipeline](data_pipeline/README.md) — Kaggle ETL, club slug canonicalization

## Development scripts

```bash
./scripts/run_migrations.sh              # apply all SQL migrations
./scripts/run_migrations.sh 007 008      # specific migrations
./scripts/run_etl.sh                     # full Kaggle → PostgreSQL pipeline
./scripts/run_ios_simulator.sh           # build & run on iOS simulator
./scripts/sync_to_developer.sh           # sync to ~/Developer/CrossBall
flutter test                             # run all tests
```

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs `flutter analyze`, `flutter test`, and `data_pipeline` pytest on push/PR.

## License

Proprietary — CrossBall © 2026
