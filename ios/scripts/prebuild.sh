#!/bin/sh
# Strip macOS extended attributes from Flutter build artifacts (Desktop/iCloud codesign fix).
APP_PATH="${FLUTTER_APPLICATION_PATH:-$(cd "$(dirname "$0")/../.." && pwd)}"

export COPYFILE_DISABLE=1

# Clean known build output trees (including native_assets/objective_c.framework).
for dir in \
  "$APP_PATH/build" \
  "$APP_PATH/.dart_tool/flutter_build" \
  "$APP_PATH/lib"
do
  if [ -d "$dir" ]; then
    xattr -cr "$dir" 2>/dev/null || true
  fi
done
