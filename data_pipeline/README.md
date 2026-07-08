# CrossBall Data Ingestion Pipeline

Deterministic, reproducible pipeline for ingesting football player and club data from Kaggle (SoFIFA format) plus curated career patches for recent transfers/loans.

## Scope

- Top ~100 clubs
- Players with senior careers from 1990 onward
- Multi-year SoFIFA CSV merge (FIFA 23 + EA FC 24 when available) → career history
- **Curated patches** for recent gaps (e.g. Rashford → Barcelona loan) — zero API cost
- Includes loan spells
- Excludes youth, reserve, and B teams
- Legal-safe club badge metadata on load
- Canonical club slugs aligned with Supabase migration `007`

## Data sources (all free)

| Source | Cost | Notes |
|--------|------|-------|
| Kaggle EA FC 24 + FIFA 23 (SoFIFA export) | Free | Primary bulk ingest |
| `data/raw/patches/career_patches.csv` | Free | Manual curation for recent transfers/loans |
| `data/raw/patches/api_football_careers.csv` | Free | API-Football transfer rows (daily sync output) |
| `data/raw/patches/enriched_careers.csv` | Free | Reconciled career deltas (weekly enrichment) |
| `data/raw/patches/player_id_aliases.csv` | Free | API-Football ↔ SoFIFA player id mapping |
| **API-Football** (`/transfers`) | Free — 100 req/day | Recent transfers & loans (auto sync) |

No paid APIs required. Re-runs **update** existing career rows (end dates, source) instead of ignoring conflicts.

### API-Football (recommended for fresh data)

1. Register free at https://www.api-football.com/ (no credit card)
2. Copy API key to `data_pipeline/.env`:
   ```
   API_FOOTBALL_KEY=your_key_here
   ```
3. Run (uses ~30 of 100 daily requests by default):
   ```bash
   chmod +x scripts/sync_api_football.sh
   ./scripts/sync_api_football.sh        # 30 teams
   ./scripts/sync_api_football.sh 30 30  # next 30 teams (offset 30)
   ```

Responses are **cached 30 days** locally — re-runs are free until cache expires.

**Quota tips (free plan):**
- 100 requests/day, 10/minute
- Default sync = 30 teams = 30 requests
- Full top-club sweep (~54 teams) = 2 days (`offset 0` then `offset 30`)
- Manual patches always override API rows for the same player/club/date

## Automation (recommended)

Data sync is **not automatic until you enable it**. Two options:

### Option A — GitHub Actions (zero server, recommended)

1. Push repo to GitHub
2. Add **Repository secrets** (Settings → Secrets → Actions):
   - `DATABASE_URL` — Supabase Postgres URI
   - `API_FOOTBALL_KEY` — free API key
   - *(optional)* `KAGGLE_USERNAME` + `KAGGLE_KEY` for weekly full Kaggle fetch
3. Workflows run automatically:
   - **Daily 00:00 UTC** (03:00 TRT) — pending migrations → API-Football (30 teams) → light patch load → daily puzzle
   - **Saturday 07:00 Istanbul** — career enrichment (all mapped teams, reconcile + DB load)
   - **Sunday 08:00 Istanbul** — weekly Kaggle + full graph refresh

Manual trigger: GitHub → Actions → "Data Sync (Daily)" → Run workflow.

See `.github/workflows/README.md` for details.

### Option B — Local cron (Mac/Linux)

```bash
chmod +x scripts/install_local_cron.sh scripts/run_scheduled_sync.sh scripts/run_scheduled_etl.sh
./scripts/install_local_cron.sh --install
```

Requires `data_pipeline/.env` on the machine (same keys as above). Logs: `logs/data-sync.log`.

### Manual (development only)

```bash
./scripts/sync_api_football.sh      # one-off API sync (~30 teams)
./scripts/run_etl.sh                # one-off full ETL
./scripts/apply_career_patches.sh   # manual patches only
./scripts/run_career_enrichment.sh  # reconcile + gap report (CSV only)
CAREER_ENRICH_LOAD=1 ./scripts/run_career_enrichment.sh  # apply enriched patches to DB
```

## Setup

```bash
cd data_pipeline
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # set DATABASE_URL (see examples in .env.example)
```

**`DATABASE_URL` by environment:**

| Where | Connection | Example host |
|-------|------------|--------------|
| Local Supabase CLI | Direct | `localhost:54322` |
| Mac → production | Direct | `db.<project-ref>.supabase.co:5432` |
| GitHub Actions | Transaction pooler | `aws-0-ap-south-1.pooler.supabase.com:6543` |

Never commit `.env` — only `.env.example` with placeholders.

### Kaggle API (for automatic download)

1. Create API token at https://www.kaggle.com/settings
2. Save as `~/.kaggle/kaggle.json` (chmod 600)
3. Accept dataset terms on Kaggle for:
   - https://www.kaggle.com/datasets/stefanoleone992/ea-sports-fc-24-complete-player-dataset
   - https://www.kaggle.com/datasets/stefanoleone992/fifa-23-complete-player-dataset

**Manual alternative:** Download CSV files and place them in `data/raw/kaggle/`.

### Quick patch update (recent loans/transfers only)

From project root — no Kaggle download required:

```bash
chmod +x scripts/apply_career_patches.sh
./scripts/apply_career_patches.sh
```

Add rows to `data_pipeline/data/raw/patches/career_patches.csv` (SoFIFA player `id`, club, dates, `is_loan`).

### Career enrichment (stale transfer data)

When players show only an old club (e.g. after a summer transfer), run enrichment to reconcile open stints and backfill missing clubs from API-Football:

```bash
# From project root — gap report only (no DB writes)
./scripts/run_career_enrichment.sh --skip-api-sync

# Full run + load to Supabase
CAREER_ENRICH_LOAD=1 ./scripts/run_career_enrichment.sh
```

Or from `data_pipeline/`:

```bash
python3 -m pipeline career-gap-report
python3 -m pipeline career-enrich --skip-api-sync
python3 -m pipeline career-enrich --load   # apply enriched_careers.csv to PostgreSQL
```

Output:
- `data/raw/patches/enriched_careers.csv` — reconciled deltas (committed after weekly job)
- `reports/career_gaps.csv` — players still needing manual review (gitignored locally; GitHub artifact)

The script auto-creates `.venv`, prefers `python3`, and reads `DATABASE_URL` from `data_pipeline/.env`.

## Usage

### Full ETL (recommended)

From project root:

```bash
chmod +x scripts/run_etl.sh
./scripts/run_etl.sh
```

Or from `data_pipeline/`:

```bash
python -m pipeline run-all
```

This runs: **fetch-kaggle → transform-kaggle → load (PostgreSQL)**

### Step by step

```bash
# 1. Download from Kaggle
python -m pipeline fetch-kaggle --output data/raw/kaggle

# 2. Transform SoFIFA CSV → CrossBall format
python -m pipeline transform-kaggle \
  --input data/raw/kaggle \
  --players-out data/raw/players.csv \
  --clubs-out data/raw/clubs.csv

# 3. Validate + load to PostgreSQL
python -m pipeline run \
  --input data/raw/players.csv \
  --clubs data/raw/clubs.csv
```

### Remote Supabase

Set `DATABASE_URL` in `data_pipeline/.env` (not the repo root `.env`).

```bash
# Local Mac: direct connection (Connect modal, port 5432) works fine.
# GitHub Actions: must use Transaction pooler (IPv4) — CrossBall region is ap-south-1:
export DATABASE_URL="postgresql://postgres.kseqeqpoouneaiymdzpq:[password]@aws-0-ap-south-1.pooler.supabase.com:6543/postgres"
python3 -m pipeline run-all
```

After load, refresh intersections:

```sql
SELECT public.refresh_player_club_intersections();
```

## Pipeline stages

| Command | Description |
|---------|-------------|
| `fetch-kaggle` | Download EA FC 24 + FIFA 23 SoFIFA exports (free) |
| `transform-kaggle` | SoFIFA CSV → players.csv + clubs.csv + merge patches |
| `apply-patches` | Load curated career patches only (fast incremental update) |
| `sync-api-football` | Fetch transfers from API-Football → patch CSV (+ optional `--load`) |
| `career-gap-report` | Detect stale/missing career stints → `reports/career_gaps.csv` |
| `career-enrich` | API sync (all teams) + reconcile + write `enriched_careers.csv` (+ optional `--load`) |
| `ensure-daily` | Ensure today's global daily puzzle exists in PostgreSQL |
| `apply-patches --light` | Patch load without dedupe/graph refresh (daily CI sync) |
| `run` | Validate + upsert to PostgreSQL |
| `run-all` | All of the above |

## Club slug canonicalization

The ETL maps legacy/alternate club names to canonical slugs via `LEGACY_CLUB_SLUGS` in `pipeline/club_metadata.py` (e.g. `FC Barcelona` → `barcelona`, `Bayern Munich` → `bayern-munich`). This must stay in sync with migration `007_club_slug_canonical.sql` on the database side.

## Output

- `data/raw/players.csv` — career rows (one row per player-club stint)
- `data/raw/clubs.csv` — clubs with badge metadata
- Deterministic content hash logged at end

## Tests

```bash
cd data_pipeline
pytest tests/ -q
```

CI runs these tests on every push (see `.github/workflows/ci.yml`).

**Important:** Never run two sync/load jobs in parallel (causes PostgreSQL deadlocks on `players` upsert).

## Verify

```sql
SELECT COUNT(*) FROM clubs;
SELECT COUNT(*) FROM players;
SELECT COUNT(*) FROM player_career_history;

-- Example intersection check
SELECT public.validate_player_intersection(
  (SELECT id FROM players WHERE name ILIKE '%lewandowski%' LIMIT 1),
  'barcelona',
  'bayern-munich'
);
```
