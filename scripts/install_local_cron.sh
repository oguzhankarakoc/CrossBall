#!/usr/bin/env bash
# Install local macOS/Linux cron jobs for CrossBall data sync (optional alternative to GitHub Actions).
#
# Usage:
#   ./scripts/install_local_cron.sh          # print crontab lines
#   ./scripts/install_local_cron.sh --install   # append to user crontab
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SYNC="$ROOT/scripts/run_scheduled_sync.sh"
ETL="$ROOT/scripts/run_scheduled_etl.sh"

CRON_DAILY="0 7 * * * cd $ROOT && $SYNC >> $ROOT/logs/data-sync.log 2>&1"
CRON_WEEKLY="0 8 * * 0 cd $ROOT && $ETL >> $ROOT/logs/data-etl.log 2>&1"

mkdir -p "$ROOT/logs"

if [[ "${1:-}" == "--install" ]]; then
  (crontab -l 2>/dev/null | grep -v "run_scheduled_sync.sh" | grep -v "run_scheduled_etl.sh"; echo "$CRON_DAILY"; echo "$CRON_WEEKLY") | crontab -
  echo "Installed crontab entries:"
  crontab -l | grep -E "scheduled_sync|scheduled_etl"
  echo ""
  echo "Logs: $ROOT/logs/data-sync.log and data-etl.log"
  echo "Requires data_pipeline/.env with DATABASE_URL and API_FOOTBALL_KEY"
else
  cat <<EOF
Add these lines to crontab (crontab -e):

# CrossBall — daily transfer sync (07:00 local)
$CRON_DAILY

# CrossBall — weekly bulk ETL (Sunday 08:00 local)
$CRON_WEEKLY

Or run: ./scripts/install_local_cron.sh --install

Prefer zero-maintenance? Use GitHub Actions instead — see .github/workflows/README.md
EOF
fi
