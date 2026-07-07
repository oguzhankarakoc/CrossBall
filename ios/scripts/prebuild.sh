#!/bin/sh
# Strip macOS extended attributes + avoid iCloud Desktop codesign failures.
APP_PATH="${FLUTTER_APPLICATION_PATH:-$(cd "$(dirname "$0")/../.." && pwd)}"

export COPYFILE_DISABLE=1

# Desktop/Documents are often iCloud-synced; codesign rejects App.framework there.
case "$APP_PATH" in
  *"/Desktop/"*|*"/Documents/"*)
    EXTERNAL_BUILD="/tmp/crossball_flutter_build"
    mkdir -p "$EXTERNAL_BUILD"
    if [ -e "$APP_PATH/build" ] && [ ! -L "$APP_PATH/build" ]; then
      rm -rf "$APP_PATH/build"
    fi
    if [ ! -L "$APP_PATH/build" ]; then
      ln -sf "$EXTERNAL_BUILD" "$APP_PATH/build"
    fi
    EXTERNAL_DART_TOOL="/tmp/crossball_dart_tool_build"
    mkdir -p "$EXTERNAL_DART_TOOL"
    DART_BUILD="$APP_PATH/.dart_tool/flutter_build"
    if [ -e "$DART_BUILD" ] && [ ! -L "$DART_BUILD" ]; then
      rm -rf "$DART_BUILD"
    fi
    if [ ! -L "$DART_BUILD" ]; then
      ln -sf "$EXTERNAL_DART_TOOL" "$DART_BUILD"
    fi
    ;;
esac

# Clean known build output trees (including native_assets/objective_c.framework).
for dir in \
  "$APP_PATH/build" \
  "$APP_PATH/.dart_tool/flutter_build" \
  "$APP_PATH/lib" \
  "$APP_PATH/assets" \
  "$APP_PATH/.env"
do
  if [ -e "$dir" ]; then
    xattr -cr "$dir" 2>/dev/null || true
  fi
done
