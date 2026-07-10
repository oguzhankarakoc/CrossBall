#!/usr/bin/env bash
# Set Supabase secrets for server-side FCM streak push (HTTP v1).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_REF="${SUPABASE_PROJECT_REF:-kseqeqpoouneaiymdzpq}"

usage() {
  cat <<EOF
Usage:
  $0 --service-account /path/to/firebase-adminsdk.json [--cron-secret SECRET]

Generates CRON_SECRET if omitted, then sets:
  FCM_SERVICE_ACCOUNT_JSON
  CRON_SECRET

Prerequisites:
  - supabase login
  - supabase link --project-ref $PROJECT_REF
  - Firebase Console → Service accounts → Generate new private key
  - Google Cloud → Enable "Firebase Cloud Messaging API"
EOF
}

SA_FILE=""
CRON_SECRET_VALUE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --service-account)
      SA_FILE="$2"
      shift 2
      ;;
    --cron-secret)
      CRON_SECRET_VALUE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$SA_FILE" || ! -f "$SA_FILE" ]]; then
  echo "Missing --service-account file."
  usage
  exit 1
fi

if [[ -z "$CRON_SECRET_VALUE" ]]; then
  CRON_SECRET_VALUE="$(openssl rand -hex 32)"
  echo "Generated CRON_SECRET=$CRON_SECRET_VALUE"
fi

cd "$ROOT"

echo "Setting Supabase secrets for project $PROJECT_REF ..."
supabase secrets set \
  FCM_SERVICE_ACCOUNT_JSON="$(cat "$SA_FILE")" \
  CRON_SECRET="$CRON_SECRET_VALUE" \
  --project-ref "$PROJECT_REF"

echo "Deploying push edge functions ..."
supabase functions deploy register-push-token send-streak-reminder --project-ref "$PROJECT_REF"

cat <<EOF

Done.

Manual test:
  curl -sS -X POST \\
    "https://${PROJECT_REF}.supabase.co/functions/v1/send-streak-reminder" \\
    -H "Authorization: Bearer ${CRON_SECRET_VALUE}" \\
    -H "Content-Type: application/json"

Cron (Supabase Dashboard → Edge Functions → send-streak-reminder → Schedules):
  Cron: 0 15 * * *
  Header: Authorization: Bearer ${CRON_SECRET_VALUE}

Save CRON_SECRET somewhere safe (1Password / .env.local — never commit).
EOF
