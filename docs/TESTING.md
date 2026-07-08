# CrossBall Testing Strategy

## Overview

Testing pyramid for CrossBall MVP with emphasis on domain logic and critical user flows.

```
        ┌─────────────┐
        │  Widget E2E │  Key flows
        ├─────────────┤
        │ Integration │  Repository + cache
        ├─────────────┤
        │    Unit     │  Domain, scoring, search
        └─────────────┘
```

**Current status:** 60+ Flutter tests + 25 pipeline pytest tests, all passing in CI.

## Coverage targets

| Layer | Target | Priority |
|-------|--------|----------|
| Domain (scoring, rarity, anti-cheat) | 90%+ | P0 |
| Utils (string normalizer, club display) | 95%+ | P0 |
| Data (repositories, cache) | 80%+ | P1 |
| Widget (puzzle grid, app smoke) | Key paths | P1 |
| Integration | Daily puzzle flow | P2 |

## Unit tests

### Scoring (`test/core/scoring_test.dart`)

- Rarity score calculation
- Speed bonus tiers
- Mistake penalty
- Session score aggregation

### String normalizer (`test/core/string_normalizer_test.dart`)

- Accent insensitivity: `özil` == `ozil`
- Fuzzy match tolerance
- Case insensitivity

### Anti-cheat (`test/core/anti_cheat_test.dart`)

- Metadata fields present
- Evaluate runs without error

### Club identity (`test/core/club_identity_test.dart`)

- Barcelona → abstract stripes
- Chelsea → abstract lion
- Liverpool → abstract wings
- Unknown club deterministic fallback
- All 105 DB seed slugs have curated symbol (not generic shield)

### Theme contrast (`test/core/app_theme_test.dart`)

- Dark mode `headlineSmall` uses light text
- Light mode `headlineSmall` uses dark text

### Club display (`test/core/club_display_test.dart`)

- Short name resolution (Man United, Bayern)
- DB `short_name` overrides registry

### Deep links (`test/core/deep_link_test.dart`)

- `crossball://challenge/abc123` parsing
- Query param variant

### Offline cache (`test/core/offline_cache_test.dart`)

- Daily puzzle cache round-trip
- Recent picks order and limit

## Widget tests

| File | Coverage |
|------|----------|
| `test/widget_test.dart` | App smoke test |
| `test/features/puzzle/puzzle_grid_test.dart` | 9 cells + 6 club badges render |

## Data pipeline tests

```bash
cd data_pipeline
pytest tests/ -q
```

- Youth team filtering
- Club name canonicalization
- Transform output shape
- Career reconcile + gap report + enrichment deltas
- Idempotent migration runner (`run_migrations.py`)
- API-Football sync + player alias resolution

## CI pipeline

`.github/workflows/ci.yml` runs on push/PR to `main` and `feature/**`:

```yaml
flutter:
  - flutter pub get
  - flutter gen-l10n
  - flutter analyze
  - flutter test

pipeline:
  - pip install -r requirements.txt
  - pytest tests/ -q
```

## Manual QA checklist

- [ ] First launch shows onboarding (3 screens, skippable)
- [ ] Daily puzzle loads 3×3 grid with 6 club badges
- [ ] Player search: fuzzy, accent-insensitive, rich cards with club chips
- [ ] Correct answer (e.g. Lewandowski for Barcelona × Bayern) shows rarity tier
- [ ] Wrong answer shows "Yanlış" feedback modal
- [ ] Timer runs during background
- [ ] Banners only on Home/Stats/Result
- [ ] No banners during puzzle gameplay
- [ ] Challenge create + share link
- [ ] EN/TR/DE localization renders
- [ ] Light Pitch and Dark Stadium themes switch correctly

## Test commands

```bash
flutter test
flutter test test/core/
flutter test test/features/
flutter analyze

cd data_pipeline && pytest tests/ -q
```
