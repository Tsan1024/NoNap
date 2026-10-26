#!/usr/bin/env bash
# Complete Developer ID distribution from an already signed app. No installation.
# Usage: SIGNING_IDENTITY='Developer ID Application: ...' ./macos/notarize.sh PROFILE [OUT]
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="${1:?Usage: notarize.sh KEYCHAIN_PROFILE [OUTPUT_DIRECTORY]}"
OUT="${2:-$REPO/dist}"
: "${SIGNING_IDENTITY:?Set SIGNING_IDENTITY to your Developer ID Application identity}"
OUT="$(cd "$OUT" && pwd)"
APP="$OUT/NoNap.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
DMG="$OUT/NoNap-$VERSION.dmg"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Refuse ad-hoc/development signatures before uploading anything.
codesign --verify --deep --strict "$APP"
SIGNATURE="$(codesign -dvv "$APP" 2>&1)"
[[ "$SIGNATURE" == *"Authority=Developer ID Application:"* ]] || { echo 'Developer ID signature required' >&2; exit 1; }
[[ "$SIGNATURE" == *"runtime"* ]] || { echo 'Hardened Runtime required' >&2; exit 1; }

submit() {
  local artifact="$1" report="$2" status
  # Keep Apple's submission ID even when waiting or submission fails.
  if ! xcrun notarytool submit "$artifact" --keychain-profile "$PROFILE" --wait --output-format json > "$report"; then
    cat "$report"
    echo 'Notarization did not complete. Inspect the submission before retrying.' >&2
    return 1
  fi
  cat "$report"
  status="$(plutil -extract status raw -o - "$report")"
  [ "$status" = Accepted ] || { echo 'Apple did not accept this submission; use notarytool log with its ID.' >&2; return 1; }
}

ditto -c -k --keepParent "$APP" "$TMP/NoNap.zip"
submit "$TMP/NoNap.zip" "$OUT/notarization-app.json"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
spctl --assess --type execute --verbose=2 "$APP"

# Package the stapled app, then notarize and staple the outer disk image as well.
SKIP_BUILD=1 "$REPO/package.sh" "$OUT"
submit "$DMG" "$OUT/notarization-dmg.json"
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
codesign --verify --strict "$DMG"
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG"
(cd "$OUT" && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256")
echo "Ready for distribution: $DMG"
