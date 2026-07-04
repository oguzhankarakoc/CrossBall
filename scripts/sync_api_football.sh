#!/usr/bin/env bash
# Sync recent transfers from API-Football free tier and load into PostgreSQL.
# Requires API_FOOTBALL_KEY in data_pipeline/.env (free: 100 requests/day).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIPELINE_DIR="$ROOT/data_pipeline"

cd "$PIPELINE_DIR"

if [[ ! -d .venv ]]; then
  python3 -m venv .venv
fi

source .venv/bin/activate
pip install -q -r requirements.txt

LIMIT="${1:-30}"
OFFSET="${2:-0}"

python -m pipeline sync-api-football \
  --limit "$LIMIT" \
  --offset "$OFFSET" \
  --load
