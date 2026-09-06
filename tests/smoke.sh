#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

env CLANG_MODULE_CACHE_PATH="$TMP/cache" SWIFT_MODULECACHE_PATH="$TMP/cache" \
  swiftc -typecheck -parse-as-library -framework AppKit -framework ServiceManagement "$REPO/App.swift"
bash -n "$REPO"/{build,grant,install,package,uninstall}.sh
plutil -lint "$REPO/Info.plist" >/dev/null

if SLEEPLESS_USER="bad user" "$REPO/grant.sh" --yes >/dev/null 2>&1; then
  echo "grant.sh accepted an unsafe account name" >&2
  exit 1
fi
if rg -q 'resourcePath.*grant\.sh|/bin/bash.*grant' "$REPO/App.swift"; then
  echo "App.swift must not execute a bundle grant script as root" >&2
  exit 1
fi

echo "smoke checks passed"
