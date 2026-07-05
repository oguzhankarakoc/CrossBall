#!/usr/bin/env bash
# Scheduled API-Football sync with daily team rotation (free tier: 100 req/day).
# Used by GitHub Actions cron and optional local crontab.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIPELINE_DIR="$ROOT/data_pipeline"
LIMIT="${SYNC_LIMIT:-30}"

# Daily sync: upsert patches only — skip full dedupe + graph refresh (weekly ETL rebuilds).
export PATCH_LOAD_LIGHT="${PATCH_LOAD_LIGHT:-1}"
# Medium tier generates faster than hard; still valid for daily leaderboard.
export ENSURE_DAILY_TIER="${ENSURE_DAILY_TIER:-medium}"
# Fail fast on runaway SQL instead of hanging until GitHub cancels the job.
export DB_STATEMENT_TIMEOUT="${DB_STATEMENT_TIMEOUT:-30min}"

cd "$PIPELINE_DIR"

if [[ "${CI:-}" == "true" || "${USE_SYSTEM_PYTHON:-}" == "1" ]]; then
  echo "=== Using system Python (CI / USE_SYSTEM_PYTHON) ==="
else
  if [[ ! -d .venv ]]; then
    python3 -m venv .venv
  fi
  source .venv/bin/activate
  pip install -q -r requirements.txt
fi

# Rotate offset through mapped teams (covers full set over ~2 days at 30 req/day).
if [[ -n "${SYNC_OFFSET:-}" ]]; then
  OFFSET="$SYNC_OFFSET"
else
  OFFSET="$(python3 <<'PY'
import json
from datetime import date
from pathlib import Path

team_ids = json.loads(Path("data/raw/api_football/team_ids.json").read_text())
limit = int(__import__("os").environ.get("SYNC_LIMIT", "30"))
day = date.today().timetuple().tm_yday
print((day * limit) % max(len(team_ids), 1))
PY
)"
fi

echo "=== Mark daily puzzle rollout (UTC midnight refresh) ==="
python -m pipeline daily-rollout-begin

echo "=== Scheduled API-Football sync (offset=$OFFSET limit=$LIMIT light=$PATCH_LOAD_LIGHT tier=$ENSURE_DAILY_TIER) ==="
python -m pipeline sync-api-football --offset "$OFFSET" --limit "$LIMIT" --load

echo "=== Ensure today's daily puzzle exists ==="
python -m pipeline ensure-daily

echo "=== Scheduled sync complete ==="
