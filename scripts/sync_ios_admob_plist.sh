#!/usr/bin/env bash
# Sync AdMob iOS App ID from .env into Info.plist (GADApplicationIdentifier).
# Usage: ./scripts/sync_ios_admob_plist.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
PLIST="$ROOT/ios/Runner/Info.plist"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing .env — copy from .env.example first."
  exit 1
fi

APP_ID="$(grep -E '^ADMOB_IOS_APP_ID=' "$ENV_FILE" | cut -d= -f2- | tr -d '\r' | xargs)"
if [[ -z "$APP_ID" ]]; then
  echo "ADMOB_IOS_APP_ID is empty in .env"
  exit 1
fi

/usr/libexec/PlistBuddy -c "Set :GADApplicationIdentifier $APP_ID" "$PLIST" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :GADApplicationIdentifier string $APP_ID" "$PLIST"

echo "Updated GADApplicationIdentifier → $APP_ID"
