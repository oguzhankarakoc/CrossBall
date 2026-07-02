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

## Coverage targets

| Layer | Target | Priority |
|-------|--------|----------|
| Domain (scoring, rarity, anti-cheat) | 90%+ | P0 |
| Utils (string normalizer) | 95%+ | P0 |
| Data (repositories) | 80%+ | P1 |
| Widget (onboarding, puzzle grid) | Key paths | P1 |
| Integration | Daily puzzle flow | P2 |

## Unit tests

### Scoring (`test/core/scoring_test.dart`)

- Rarity score calculation
- Speed bonus tiers
- Mistake penalty
- Session score aggregation

### Rarity (`test/core/rarity_test.dart`)

- Tier boundaries (50%, 25%, 10%, 3%)

### String normalizer (`test/core/string_normalizer_test.dart`)

- Accent insensitivity: `özil` == `ozil`
- Fuzzy match tolerance
- Case insensitivity

### Anti-cheat (`test/core/anti_cheat_test.dart`)

- Suspicious duration detection
- Background ratio flagging
- Inactivity period counting

## Widget tests

- App smoke test (existing)
- Onboarding page navigation
- Puzzle grid cell tap states
- Search modal empty state shows recent/popular

## Integration tests

- Offline daily puzzle cache hit/miss
- Pending answer queue flush on reconnect
- Demo validation flow end-to-end

## Data pipeline tests

```bash
cd data_pipeline
python -m pytest tests/  # when pytest added
python -m pipeline run --input data/raw/players.csv --clubs data/raw/clubs.csv
```

- Youth team filtering
- Duplicate normalization
- Content hash determinism

## CI pipeline (recommended)

```yaml
# .github/workflows/ci.yml
- flutter analyze
- flutter test
- python -m pipeline validate (dry run)
```

## Manual QA checklist

- [ ] First launch shows onboarding (3 screens, skippable)
- [ ] Daily puzzle loads (online + cached offline)
- [ ] Player search: fuzzy, accent-insensitive
- [ ] Correct answer shows rarity tier
- [ ] Timer runs during background
- [ ] Banners only on Home/Stats/Result
- [ ] No banners during puzzle gameplay
- [ ] Challenge create + share link
- [ ] EN/TR/DE localization renders

## Test commands

```bash
flutter test
flutter test test/core/
flutter analyze
```
