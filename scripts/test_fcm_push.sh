#!/usr/bin/env bash
# Send a test FCM push to one or more device tokens (FCM HTTP v1).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SA_FILE="${FCM_SERVICE_ACCOUNT_FILE:-$HOME/Downloads/crossball-b4a97-firebase-adminsdk-fbsvc-2960d04d85.json}"

usage() {
  cat <<EOF
Usage:
  $0 <fcm_token> [fcm_token2 ...]
  $0 --service-account /path/to.json <fcm_token> ...

Sends a test notification via FCM HTTP v1.
Tokens must be FCM registration tokens (long, often contain :APA91b...).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --service-account)
      SA_FILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

if [[ ! -f "$SA_FILE" ]]; then
  echo "Service account file not found: $SA_FILE"
  exit 1
fi

TOKENS=("$@")

node "$ROOT/scripts/test_fcm_push.mjs" "$SA_FILE" "${TOKENS[@]}"
