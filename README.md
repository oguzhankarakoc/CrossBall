# CrossBall

**Connect clubs. Prove your football IQ.**

Production-grade football intersection puzzle app for iOS and Android.

## Stack

- **Flutter** + Riverpod + GoRouter
- **Supabase** (PostgreSQL, Edge Functions)
- **AdMob** (banner, interstitial, rewarded)
- **Python** data ingestion pipeline

## Quick start

```bash
cp .env.example .env   # add Supabase credentials
flutter pub get
flutter gen-l10n
flutter run
```

## Project structure

```
lib/
├── core/           # theme, routing, cache, scoring, anti-cheat
├── shared/         # providers, widgets
└── features/       # auth, puzzle, search, challenge, stats, ads, premium
docs/               # architecture, testing strategy
supabase/           # migrations, edge functions
data_pipeline/      # Python ingest pipeline
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Testing Strategy](docs/TESTING.md)
- [Supabase Setup](supabase/README.md)
- [Data Pipeline](data_pipeline/README.md)

## Game modes

| Mode | Grid | Access |
|------|------|--------|
| Daily Challenge | 3×3 | Free |
| Friend Challenge | 3×3 | Free |
| Practice | 3×3 | Free (limited) |
| Practice | 4×4 | Premium |

## License

Proprietary — CrossBall © 2026
