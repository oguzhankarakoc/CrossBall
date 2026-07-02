# CrossBall Data Ingestion Pipeline

Deterministic, reproducible pipeline for ingesting football player and club data.

## Scope

- Top 100 clubs
- Players with senior careers from 1990 onward
- Includes loan spells
- Excludes youth, reserve, and B teams

## Setup

```bash
cd data_pipeline
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # set DATABASE_URL
```

## Usage

```bash
# Full pipeline
python -m pipeline run --input data/raw/players.csv --clubs data/raw/clubs.csv

# Individual steps
python -m pipeline ingest --input data/raw/players.csv
python -m pipeline normalize
python -m pipeline validate
python -m pipeline load
```

## Pipeline stages

1. **ingest** — Read raw CSV/JSON data
2. **normalize** — Clean names, slugs, dates; filter youth/reserve
3. **validate** — Referential integrity, duplicate detection
4. **load** — Upsert to PostgreSQL

## Output

Deterministic hash logged at end for reproducibility verification.
