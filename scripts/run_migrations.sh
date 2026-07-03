#!/usr/bin/env bash
# Run Supabase SQL migrations against DATABASE_URL (data_pipeline/.env)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIPELINE_DIR="$ROOT/data_pipeline"

cd "$PIPELINE_DIR"

if [[ ! -d .venv ]]; then
  echo "Creating Python venv..."
  python3 -m venv .venv
fi

source .venv/bin/activate
pip install -q -r requirements.txt

if [[ ! -f .env ]]; then
  echo "Missing data_pipeline/.env — copy .env.example and set DATABASE_URL"
  exit 1
fi

python "$ROOT/scripts/run_migrations.py" "$@"
