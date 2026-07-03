# CrossBall Data Ingestion Pipeline

Deterministic, reproducible pipeline for ingesting football player and club data from Kaggle (SoFIFA format).

## Scope

- Top ~100 clubs
- Players with senior careers from 1990 onward
- Multi-year SoFIFA CSV merge → career history
- Includes loan spells
- Excludes youth, reserve, and B teams
- Legal-safe club badge metadata on load
- Canonical club slugs aligned with Supabase migration `007`

## Setup

```bash
cd data_pipeline
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # set DATABASE_URL (Supabase local or remote)
```

### Kaggle API (for automatic download)

1. Create API token at https://www.kaggle.com/settings
2. Save as `~/.kaggle/kaggle.json` (chmod 600)
3. Accept dataset terms: https://www.kaggle.com/datasets/maso0dahmed/football-players-data

**Manual alternative:** Download CSV files and place them in `data/raw/kaggle/`.

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

Set `DATABASE_URL` in `.env` to your Supabase Postgres connection string (Settings → Database → URI).

```bash
export DATABASE_URL="postgresql://postgres.[ref]:[password]@aws-0-eu-central-1.pooler.supabase.com:6543/postgres"
python -m pipeline run-all
```

After load, refresh intersections:

```sql
SELECT public.refresh_player_club_intersections();
```

## Pipeline stages

| Command | Description |
|---------|-------------|
| `fetch-kaggle` | Download maso0dahmed/football-players-data |
| `transform-kaggle` | SoFIFA CSV → players.csv + clubs.csv |
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
