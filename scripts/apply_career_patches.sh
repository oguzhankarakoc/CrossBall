#!/usr/bin/env bash
# Apply curated career patches (recent loans/transfers) without full Kaggle download.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIPELINE_DIR="$ROOT/data_pipeline"

cd "$PIPELINE_DIR"

if [[ ! -d .venv ]]; then
  python3 -m venv .venv
fi

source .venv/bin/activate
pip install -q -r requirements.txt

python -m pipeline apply-patches \
  --patches data/raw/patches/career_patches.csv \
  --clubs data/raw/clubs.csv
