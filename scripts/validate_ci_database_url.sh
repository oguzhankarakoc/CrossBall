#!/usr/bin/env bash
# GitHub Actions runners cannot reach Supabase direct host (IPv6-only db.*.supabase.co:5432).
# CI must use the transaction pooler (IPv4) for this project region (ap-south-1).
set -euo pipefail

if [[ "${GITHUB_ACTIONS:-}" != "true" ]]; then
  exit 0
fi

url="${DATABASE_URL:-}"
if [[ -z "$url" ]]; then
  echo "Missing DATABASE_URL"
  exit 1
fi

if [[ "$url" == *"db."*".supabase.co:5432"* ]]; then
  echo "::error::GitHub Actions cannot use Supabase direct connection (db.*.supabase.co:5432 — IPv6 only)."
  echo ""
  echo "Update the DATABASE_URL secret to Transaction pooler (port 6543):"
  echo "  postgresql://postgres.kseqeqpoouneaiymdzpq:[PASSWORD]@aws-0-ap-south-1.pooler.supabase.com:6543/postgres"
  echo ""
  echo "Supabase → Connect → ORM / URI → Transaction pooler → copy URI."
  echo "Use the same DB password as your local direct connection."
  exit 1
fi

if [[ "$url" == *"eu-central-1.pooler"* ]]; then
  echo "::error::Wrong pooler region. CrossBall project is in ap-south-1, not eu-central-1."
  echo "Use: aws-0-ap-south-1.pooler.supabase.com:6543"
  exit 1
fi

if [[ "$url" != *"pooler.supabase.com"* ]]; then
  echo "::warning::DATABASE_URL does not look like a Supabase pooler URI. CI may fail to connect."
fi

echo "DATABASE_URL format OK for GitHub Actions (pooler)."
