#!/bin/sh
# App Store / device install reject objective_c.framework when simulator markers leak in,
# or when Info.plist/binary is patched after embed_and_thin without re-signing.
set -eu

MIN_IOS="${IPHONEOS_DEPLOYMENT_TARGET:-13.0}"

if [ -z "${TARGET_BUILD_DIR:-}" ] || [ -z "${WRAPPER_NAME:-}" ]; then
  exit 0
fi

APP_FRAMEWORKS="${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Frameworks"
[ -d "$APP_FRAMEWORKS" ] || exit 0

sign_identity="${EXPANDED_CODE_SIGN_IDENTITY:-${CODE_SIGN_IDENTITY:-}}"

find "$APP_FRAMEWORKS" -name 'objective_c.framework' -type d 2>/dev/null | while IFS= read -r framework; do
  binary="${framework}/objective_c"
  [ -f "$binary" ] || continue

  patched=false

  if lipo -info "$binary" >/dev/null 2>&1; then
    for slice in x86_64 i386; do
      if lipo -info "$binary" 2>/dev/null | grep -q "$slice"; then
        lipo -remove "$slice" "$binary" -output "${binary}.lipo" 2>/dev/null || true
        if [ -f "${binary}.lipo" ]; then
          mv "${binary}.lipo" "$binary"
          patched=true
        fi
      fi
    done
  fi

  if xcrun vtool -show-build "$binary" 2>/dev/null | grep -q 'platform IOSSIMULATOR'; then
    xcrun vtool -set-build-version ios "$MIN_IOS" "$MIN_IOS" -replace \
      -output "${binary}.vtool" "$binary"
    mv "${binary}.vtool" "$binary"
    patched=true
  fi

  plist="${framework}/Info.plist"
  if [ -f "$plist" ]; then
    /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion $MIN_IOS" "$plist" 2>/dev/null || \
      /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string $MIN_IOS" "$plist" 2>/dev/null || true
    patched=true
  fi

  # embed_and_thin signs frameworks first; any patch above invalidates the signature.
  if [ "$patched" = true ] && [ -n "$sign_identity" ] && [ "$sign_identity" != "-" ]; then
    xattr -cr "$framework" 2>/dev/null || true
    /usr/bin/codesign --force --sign "$sign_identity" --timestamp=none "$binary"
    /usr/bin/codesign --force --sign "$sign_identity" --timestamp=none "$framework"
  fi
done
