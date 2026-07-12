#!/usr/bin/env bash
# Weekly bulk refresh: Kaggle (if credentials exist) + patches + DB load.
#
# Without Kaggle: light patch load only (manual + API-Football).
# Full enriched upsert belongs to Career Enrichment (Saturday) — redoing it
# here timed out at ~75m on 6k+ players through the Supabase pooler.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIPELINE_DIR="$ROOT/data_pipeline"

cd "$PIPELINE_DIR"

if [[ "${CI:-}" == "true" || "${USE_SYSTEM_PYTHON:-}" == "1" ]]; then
  echo "=== Using system Python (CI / USE_SYSTEM_PYTHON) ==="
  PYTHON="${PYTHON:-python3}"
  if command -v python >/dev/null 2>&1; then
    PYTHON=python
  fi
else
  if [[ ! -d .venv ]]; then
    python3 -m venv .venv
  fi
  # shellcheck disable=SC1091
  source .venv/bin/activate
  pip install -q -r requirements.txt
  PYTHON=python
fi

echo "=== Weekly ETL ==="

if [[ -n "${KAGGLE_USERNAME:-}" && -n "${KAGGLE_KEY:-}" ]]; then
  mkdir -p "$HOME/.kaggle"
  cat > "$HOME/.kaggle/kaggle.json" <<EOF
{"username":"${KAGGLE_USERNAME}","key":"${KAGGLE_KEY}"}
EOF
  chmod 600 "$HOME/.kaggle/kaggle.json"
  echo "Kaggle credentials found — running full run-all"
  "$PYTHON" -m pipeline run-all
else
  echo "No Kaggle credentials — light patches (manual + API-Football; skip enriched re-upsert)"
  if compgen -G "data/raw/kaggle/**/*.csv" > /dev/null || compgen -G "data/raw/kaggle/*.csv" > /dev/null; then
    "$PYTHON" -m pipeline transform-kaggle \
      --input data/raw/kaggle \
      --players-out data/raw/players.csv \
      --clubs-out data/raw/clubs.csv
    "$PYTHON" -m pipeline run --input data/raw/players.csv --clubs data/raw/clubs.csv
  else
    # --light: daily-sized load. Enriched careers are applied by career-enrichment-weekly.
    "$PYTHON" -m pipeline apply-patches \
      --light \
      --patches data/raw/patches/career_patches.csv \
      --clubs data/raw/clubs.csv
  fi
fi

"$PYTHON" -m pipeline ensure-daily
echo "=== Weekly ETL complete ==="
