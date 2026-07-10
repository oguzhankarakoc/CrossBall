#!/usr/bin/env bash
# Career enrichment: API-Football sync (all mapped teams) + reconcile + optional DB load.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIPELINE_DIR="$ROOT/data_pipeline"

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

if [[ ! -f .env && -z "${DATABASE_URL:-}" ]]; then
  echo "Missing data_pipeline/.env or DATABASE_URL"
  exit 1
fi

PYTHON="python3"
if [[ -n "${VIRTUAL_ENV:-}" ]] && command -v python >/dev/null 2>&1; then
  PYTHON="python"
elif [[ -x "$PIPELINE_DIR/.venv/bin/python" ]]; then
  PYTHON="$PIPELINE_DIR/.venv/bin/python"
fi

if [[ "${1:-}" == "load-only" ]]; then
  shift
  echo "=== Applying enriched career patches to database ==="
  "$PYTHON" -m pipeline apply-patches --enriched-only "$@"
  echo "=== Enriched patch load complete ==="
  exit 0
fi

LOAD_FLAG=""
if [[ "${CAREER_ENRICH_LOAD:-}" == "1" ]]; then
  LOAD_FLAG="--load"
fi

echo "=== Career enrichment (API sync + reconcile + gap report) ==="
"$PYTHON" -m pipeline career-enrich \
  --api-limit 0 \
  ${LOAD_FLAG} \
  "$@"

echo "=== Career enrichment complete ==="
