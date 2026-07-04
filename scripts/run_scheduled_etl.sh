#!/usr/bin/env bash
# Weekly bulk refresh: Kaggle (if credentials exist) + patches + DB load.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIPELINE_DIR="$ROOT/data_pipeline"

cd "$PIPELINE_DIR"

if [[ ! -d .venv ]]; then
  python3 -m venv .venv
fi
source .venv/bin/activate
pip install -q -r requirements.txt

echo "=== Weekly ETL ==="

if [[ -n "${KAGGLE_USERNAME:-}" && -n "${KAGGLE_KEY:-}" ]]; then
  mkdir -p "$HOME/.kaggle"
  cat > "$HOME/.kaggle/kaggle.json" <<EOF
{"username":"${KAGGLE_USERNAME}","key":"${KAGGLE_KEY}"}
EOF
  chmod 600 "$HOME/.kaggle/kaggle.json"
  echo "Kaggle credentials found — running full run-all"
  python -m pipeline run-all
else
  echo "No Kaggle credentials — transform committed CSV + apply patches"
  if compgen -G "data/raw/kaggle/**/*.csv" > /dev/null || compgen -G "data/raw/kaggle/*.csv" > /dev/null; then
    python -m pipeline transform-kaggle \
      --input data/raw/kaggle \
      --players-out data/raw/players.csv \
      --clubs-out data/raw/clubs.csv
    python -m pipeline run --input data/raw/players.csv --clubs data/raw/clubs.csv
  else
    python -m pipeline apply-patches \
      --patches data/raw/patches/career_patches.csv \
      --clubs data/raw/clubs.csv
  fi
fi

python -m pipeline ensure-daily
echo "=== Weekly ETL complete ==="
