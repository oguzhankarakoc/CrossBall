#!/bin/bash
# CrossBall — always open the correct Xcode workspace (~/Developer/CrossBall).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEV="$HOME/Developer/CrossBall"

echo "══════════════════════════════════════════════"
echo " CrossBall Xcode Launcher"
echo " Desktop'ta kod yaz → Xcode ~/Developer'dan build al"
echo "══════════════════════════════════════════════"

"$ROOT/scripts/sync_to_developer.sh"

cd "$DEV"
export PATH="$DEV/ios/scripts:$PATH"
export COPYFILE_DISABLE=1

echo "→ flutter pub get..."
flutter pub get

echo "→ pod install..."
cd ios
pod install
cd ..

echo ""
echo "✓ Hazır. Xcode açılıyor..."
echo "  ÖNEMLİ: Runner.xcworkspace açılmalı (Runner.xcodeproj DEĞİL)"
echo ""

open "$DEV/ios/Runner.xcworkspace"
