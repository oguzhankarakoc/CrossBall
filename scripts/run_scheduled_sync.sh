#!/usr/bin/env bash
# Scheduled API-Football sync with daily team rotation (free tier: 100 req/day).
# Phases: gate | rollout-begin | sync-fetch | sync-load | ensure-daily | all
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIPELINE_DIR="$ROOT/data_pipeline"
LIMIT="${SYNC_LIMIT:-30}"
PHASE="${1:-all}"

export PATCH_LOAD_LIGHT="${PATCH_LOAD_LIGHT:-1}"
export ENSURE_DAILY_TIER="${ENSURE_DAILY_TIER:-hard}"
export DB_STATEMENT_TIMEOUT="${DB_STATEMENT_TIMEOUT:-30min}"

cd "$PIPELINE_DIR"

if [[ "${CI:-}" == "true" || "${USE_SYSTEM_PYTHON:-}" == "1" ]]; then
  echo "=== Using system Python (CI / USE_SYSTEM_PYTHON) ==="
else
  if [[ ! -d .venv ]]; then
    python3 -m venv .venv
  fi
  # shellcheck source=/dev/null
  source .venv/bin/activate
  pip install -q -r requirements.txt
fi

compute_offset() {
  if [[ -n "${SYNC_OFFSET:-}" ]]; then
    echo "$SYNC_OFFSET"
    return
  fi
  python3 <<'PY'
import json
from datetime import date
from pathlib import Path

team_ids = json.loads(Path("data/raw/api_football/team_ids.json").read_text())
limit = int(__import__("os").environ.get("SYNC_LIMIT", "30"))
day = date.today().timetuple().tm_yday
print((day * limit) % max(len(team_ids), 1))
PY
}

run_rollout_begin() {
  echo "=== Mark daily puzzle rollout (UTC midnight refresh) ==="
  python -m pipeline daily-rollout-begin
}

run_sync_fetch() {
  local offset
  offset="$(compute_offset)"
  echo "=== Fetch API-Football transfers (offset=$offset limit=$LIMIT light=$PATCH_LOAD_LIGHT) ==="
  python -m pipeline sync-api-football --offset "$offset" --limit "$LIMIT"
}

run_sync_load() {
  echo "=== Apply career patches to database (light=$PATCH_LOAD_LIGHT) ==="
  python -m pipeline apply-patches --light
}

run_ensure_daily() {
  echo "=== Ensure today's daily puzzle exists (tier=$ENSURE_DAILY_TIER) ==="
  python -m pipeline ensure-daily
}

run_gate() {
  python -m pipeline daily-sync-gate
}

case "$PHASE" in
  gate)
    run_gate
    ;;
  rollout-begin)
    run_rollout_begin
    ;;
  sync-fetch)
    run_sync_fetch
    ;;
  sync-load)
    run_sync_load
    ;;
  ensure-daily)
    run_ensure_daily
    ;;
  all)
    run_rollout_begin
    run_sync_fetch
    run_sync_load
    run_ensure_daily
    echo "=== Scheduled sync complete ==="
    ;;
  *)
    echo "Unknown phase: $PHASE (expected gate|rollout-begin|sync-fetch|sync-load|ensure-daily|all)" >&2
    exit 2
    ;;
esac
