#!/bin/bash
# Watch Desktop project and auto-sync to ~/Developer/CrossBall for Xcode builds.
set -euo pipefail

SOURCE="/Users/oguzhankarakoc/Desktop/fluttermobilapp/CrossBall"
SYNC="$SOURCE/scripts/sync_to_developer.sh"

if ! command -v fswatch >/dev/null 2>&1; then
  echo "fswatch not installed. Install with: brew install fswatch"
  echo "Or run ./scripts/open_xcode.sh before each Xcode build."
  exit 1
fi

echo "Watching $SOURCE → ~/Developer/CrossBall"
echo "Press Ctrl+C to stop."

"$SYNC"

fswatch -o \
  --exclude 'build/' \
  --exclude '\.dart_tool/' \
  --exclude 'ios/Pods/' \
  --exclude '\.git/' \
  "$SOURCE/lib" "$SOURCE/ios" "$SOURCE/pubspec.yaml" "$SOURCE/.env" \
  | while read -r _; do
    "$SYNC"
  done
