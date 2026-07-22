# Career Truth Pass & Loading UX

Branch: `feature/career-truth-pass-and-loading-ux`  
Owners: PO (trust), Sales (soft-launch perception), CTO (pipeline + UX)

## Problem statement

1. **Stale careers** — e.g. Kerem Aktürkoğlu still shows Galatasaray as current. Users treat this as product brokenness.
2. **API coverage gaps** — SoFIFA snapshot + API-Football free tier miss transfers; Google scraping is rejected (ToS, identity collisions, unverifiable).
3. **Loading UX** — Full-screen spinners on hot paths feel slower than skeleton placeholders.

## Principles

- Prefer **structured sources** + **reconcile** over web search.
- Every automatic write must carry `source` + be replayable via CSV patches.
- Conflicts → gap report / review queue, not silent overwrite.
- Extend existing `career-enrich` / `apply-patches` — do not invent a parallel DB writer.

## Architecture (truth pass)

```
players.csv (SoFIFA base)
  + career_patches.csv (curated high-visibility)
  + api_football_careers.csv (team transfer sync)
  → merge → reconcile (close open stints)
  → enriched_careers.csv (deltas)
  → apply-patches --enriched-only / CAREER_ENRICH_LOAD
  → refresh intersections + club graph
```

### One-shot vs steady state

| Mode | When | What |
|------|------|------|
| **Truth pass** | Soft launch / after transfer windows | Curated priority players + full reconcile + gap report |
| **Weekly enrichment** | Saturday cron | API-Football sync all mapped teams + reconcile |
| **Daily light** | Nightly | Manual + API patches only (no full enriched upsert) |

### Source priority (future)

1. Curated `career_patches.csv` (human verified)
2. API-Football transfers (existing)
3. Wikidata stints (planned — structured, free; identity map required)
4. Never: raw Google SERP scrape

## Phase 1 (this branch) — ship

- [x] Plan doc
- [x] Kerem Aktürkoğlu curated patch (GS → Benfica → Fenerbahçe)
- [x] `career-truth-pass` CLI: gap report + rebuild enriched deltas without live Google
- [x] Puzzle load skeleton instead of lone spinner
- [x] Tests for Kerem reconcile path

## Phase 2 (follow-up)

- Wikidata adapter behind feature flag
- Priority queue from `career_gaps.csv` top-N for TR + big-5 clubs
- Search/home: stale-while-revalidate + fewer nested indicators

## Operator commands

```bash
# Rebuild enriched deltas from base + all patches (no API)
cd data_pipeline && python3 -m pipeline career-truth-pass

# Apply enriched deltas to PostgreSQL (requires DATABASE_URL)
cd data_pipeline && python3 -m pipeline career-truth-pass --load
# or: CAREER_ENRICH_LOAD=1 ./scripts/run_career_enrichment.sh --skip-api-sync
```

## Success metrics

- Kerem (and patched peers) validate against current clubs in search + timeline
- Gap report count for `missing_transfer_clubs` drops after weekly enrich
- Puzzle open: skeleton ≤1 full-screen spinner event

## Ops status (Jul 2026 soft launch)

| Step | Status |
|------|--------|
| Curated Kerem patch (GS → Benfica → Fenerbahçe) | Done |
| `career-truth-pass` CLI + unit test | Done |
| `AppPuzzleSkeleton` on puzzle load | Done |
| DB `--load` (enriched deltas → Supabase) | Done (`Patch load complete`) |
| Kerem DB verify (open club = Fenerbahce) | Done |

Re-run after transfer windows:

```bash
cd data_pipeline && python3 -m pipeline career-truth-pass --load
```

If load fails mid-upsert with SSL / “Can't assign requested address”, retry:

```bash
cd data_pipeline && python3 -m pipeline apply-patches --enriched-only
```
