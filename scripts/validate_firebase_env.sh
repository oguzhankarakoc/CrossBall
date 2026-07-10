#!/usr/bin/env bash
# Validate Firebase push env vars before enabling REMOTE_PUSH_ENABLED.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing .env at project root"
  exit 1
fi

# shellcheck disable=SC1090
source <(grep -E '^(REMOTE_PUSH_ENABLED|FIREBASE_)' "$ENV_FILE" | sed 's/\r$//')

ok=true
require() {
  local name="$1"
  local value="${!name:-}"
  if [[ -z "$value" ]]; then
    echo "MISSING $name"
    ok=false
  else
    echo "OK $name"
  fi
}

echo "=== Firebase push env check ==="
require FIREBASE_PROJECT_ID
require FIREBASE_MESSAGING_SENDER_ID
require FIREBASE_IOS_API_KEY
require FIREBASE_IOS_APP_ID

if [[ "${REMOTE_PUSH_ENABLED:-false}" != "true" ]]; then
  echo "WARN REMOTE_PUSH_ENABLED is not true (set to true after Firebase console setup)"
  ok=false
fi

if [[ "$ok" == true ]]; then
  echo "Firebase client config looks ready."
  echo "Next: Firebase service account + Supabase server push:"
  echo "  ./scripts/setup_fcm_push_secrets.sh --service-account /path/to/firebase-adminsdk.json"
else
  echo "Fix .env values (see docs/IOS_LAUNCH_GUIDE.md Adım 8)."
  exit 1
fi
