#!/usr/bin/env bash
# Build a drag-to-Applications DMG using only macOS tools.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${1:-$REPO/dist}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$REPO/Info.plist")"
DMG="$OUT/NoNap-$VERSION.dmg"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
DMG="$OUT/NoNap-$VERSION.dmg"
if [ "${SKIP_BUILD:-0}" != "1" ]; then
  "$REPO/build.sh" "$OUT"
fi
codesign --verify --deep --strict "$OUT/NoNap.app"
mkdir -p "$TMP/NoNap"
cp -R "$OUT/NoNap.app" "$TMP/NoNap/"
ln -s /Applications "$TMP/NoNap/Applications"
hdiutil create -quiet -volname NoNap -srcfolder "$TMP/NoNap" -ov -format UDZO "$DMG"
if [ -n "${SIGNING_IDENTITY:-}" ]; then
  codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG"
  codesign --verify --strict "$DMG"
fi
(cd "$OUT" && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256")

echo "✅ Packaged $DMG"
echo "   Checksum: $DMG.sha256"
