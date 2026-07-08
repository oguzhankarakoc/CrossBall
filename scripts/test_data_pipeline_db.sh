#!/usr/bin/env bash
# Quick check for data_pipeline DATABASE_URL (reads data_pipeline/.env only).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/data_pipeline"

if [[ ! -f .env ]]; then
  echo "Missing data_pipeline/.env — copy from .env.example and set DATABASE_URL."
  exit 1
fi

# shellcheck disable=SC1091
set -a
source .env
set +a

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL is empty in data_pipeline/.env"
  exit 1
fi

# Mask password in log output
masked="$(python3 - <<'PY'
import os, re
url = os.environ.get("DATABASE_URL", "")
print(re.sub(r":([^:@/]+)@", ":***@", url))
PY
)"
echo "Testing: $masked"

python3 - <<'PY'
from pipeline.load import get_connection
conn = get_connection()
with conn.cursor() as cur:
    cur.execute("SELECT current_database(), current_user")
    db, user = cur.fetchone()
print(f"Connection OK — database={db}, user={user}")
conn.close()
PY
