#!/bin/bash
# Create private GitHub repo and push feature branch (run after: gh auth login)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub girişi yok. Önce: gh auth login --git-protocol ssh --hostname github.com --web"
  exit 1
fi

echo "→ Private repo oluşturuluyor (veya mevcut repo kullanılıyor)..."
if gh repo view oguzhankarakoc/CrossBall >/dev/null 2>&1; then
  echo "  Repo zaten var."
else
  gh repo create CrossBall \
    --private \
    --source=. \
    --remote=origin \
    --description "CrossBall — Football intersection puzzle app (private)"
fi

echo "→ Push: feature/mvp-ui-ios-setup"
git push -u origin feature/mvp-ui-ios-setup

echo ""
echo "✓ Tamamlandı — private repo:"
gh repo view --web 2>/dev/null || echo "  https://github.com/oguzhankarakoc/CrossBall"
