#!/usr/bin/env bash
# Build a drag-to-Applications DMG using only macOS tools.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${1:-$REPO/dist}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$REPO/Info.plist")"
DMG="$OUT/Sleepless-$VERSION.dmg"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

"$REPO/build.sh" "$OUT"
mkdir -p "$TMP/Sleepless"
cp -R "$OUT/Sleepless.app" "$TMP/Sleepless/"
ln -s /Applications "$TMP/Sleepless/Applications"
hdiutil create -quiet -volname Sleepless -srcfolder "$TMP/Sleepless" -ov -format UDZO "$DMG"
shasum -a 256 "$DMG" > "$DMG.sha256"

echo "✅ Packaged $DMG"
echo "   Checksum: $DMG.sha256"
