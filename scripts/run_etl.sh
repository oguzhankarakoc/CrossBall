#!/usr/bin/env bash
# CrossBall ETL — fetch Kaggle data, transform, load to PostgreSQL
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/data_pipeline"

if [[ ! -d .venv ]]; then
  echo "Creating Python venv..."
  python3 -m venv .venv
fi

source .venv/bin/activate
pip install -q -r requirements.txt

if [[ ! -f .env ]]; then
  echo "Copy data_pipeline/.env.example → .env and set DATABASE_URL"
  cp -n .env.example .env 2>/dev/null || true
fi

echo "=== CrossBall ETL (run-all) ==="
python -m pipeline run-all "$@"

echo ""
echo "Done. Verify with:"
echo "  psql \$DATABASE_URL -c 'SELECT COUNT(*) FROM players;'"
echo "  psql \$DATABASE_URL -c 'SELECT COUNT(*) FROM player_career_history;'"
