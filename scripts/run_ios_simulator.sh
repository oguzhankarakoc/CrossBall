#!/bin/bash
# Run CrossBall on iOS Simulator.
# Desktop/iCloud paths break macOS codesign — auto-sync to ~/Developer when needed.
set -euo pipefail

SOURCE="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$SOURCE"

if [[ "$SOURCE" == *"/Desktop/"* ]] || [[ "$SOURCE" == *"/Library/Mobile Documents/"* ]]; then
  WORK="$HOME/Developer/CrossBall"
  echo "→ Desktop/iCloud path detected. Syncing to $WORK ..."
  mkdir -p "$WORK"
  rsync -a --delete \
    --exclude build \
    --exclude .dart_tool \
    --exclude ios/Pods \
    --exclude ios/.symlinks \
    --exclude ios/Podfile.lock \
    --exclude .env \
    "$SOURCE/" "$WORK/"
  if [ -f "$SOURCE/.env" ]; then
    cp "$SOURCE/.env" "$WORK/.env"
  fi
fi

cd "$WORK"
export PATH="$WORK/ios/scripts:$PATH"
export COPYFILE_DISABLE=1

echo "→ flutter pub get..."
flutter pub get

echo "→ pod install..."
cd ios && pod install && cd ..

echo "→ Launching iOS Simulator..."
flutter emulators --launch apple_ios_simulator 2>/dev/null || true
sleep 12

SIM_ID="$(flutter devices 2>/dev/null | rg -o '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}' | rg -v '^00008110' | head -1)"
if [ -z "$SIM_ID" ]; then
  echo "No iOS simulator found. Open Simulator.app manually, then rerun."
  exit 1
fi

echo "→ Running on simulator ($SIM_ID) from: $WORK"
flutter run -d "$SIM_ID"
