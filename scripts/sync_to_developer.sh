#!/bin/bash
# Sync Desktop CrossBall → ~/Developer/CrossBall (codesign-safe build path).
set -euo pipefail

SOURCE="${1:-/Users/oguzhankarakoc/Desktop/fluttermobilapp/CrossBall}"
DEST="${2:-$HOME/Developer/CrossBall}"

if [ ! -d "$SOURCE" ]; then
  echo "Source not found: $SOURCE"
  exit 1
fi

mkdir -p "$DEST"

echo "→ Syncing $SOURCE → $DEST"
rsync -a --delete \
  --exclude build \
  --exclude .dart_tool \
  --exclude ios/Pods \
  --exclude ios/.symlinks \
  --exclude ios/Podfile.lock \
  --exclude .git \
  --exclude .env \
  "$SOURCE/" "$DEST/"

if [ -f "$SOURCE/.env" ]; then
  cp "$SOURCE/.env" "$DEST/.env"
fi

chmod +x "$DEST/ios/scripts/codesign" 2>/dev/null || true
chmod +x "$DEST/ios/scripts/prebuild.sh" 2>/dev/null || true
chmod +x "$DEST/scripts/"*.sh 2>/dev/null || true

echo "✓ Sync complete: $DEST"
