#!/usr/bin/env bash
# grant.sh — install ONLY the passwordless grant that lets Sleepless toggle lid-close
# sleep without a prompt. Self-contained: works from a clone OR from inside the app
# bundle (Contents/Resources), so Homebrew-cask users can run it after install.
#
# It writes one tightly scoped sudoers drop-in (root:wheel, 0440) permitting exactly two
# commands and nothing else. See SECURITY.md. Undo with uninstall.sh (or sudo rm the file).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUDOERS_DST="/etc/sudoers.d/sleepless-disablesleep"
# Resolve the REAL user. Prefer SLEEPLESS_USER (the app passes it, because under the native
# auth sheet this script runs as root with SUDO_USER unset), then SUDO_USER, then the caller.
USER_NAME="${SLEEPLESS_USER:-${SUDO_USER:-$(id -un)}}"
# Never install a root-owned grant (it is useless and not what the user wants): if we somehow
# resolved to root/empty, fall back to the GUI console user, and refuse if still unresolved.
if [ -z "$USER_NAME" ] || [ "$USER_NAME" = "root" ]; then
  USER_NAME="$(stat -f%Su /dev/console 2>/dev/null || true)"
fi
if [ -z "$USER_NAME" ] || [ "$USER_NAME" = "root" ]; then
  echo "error: could not resolve a non-root user for the grant; refusing to install." >&2
  exit 1
fi

# Run privileged steps with sudo normally, but directly when we are ALREADY root (e.g. the
# app installs this via one native macOS auth sheet, so there is no Terminal + no sudo prompt).
SUDO="sudo"
[ "$(id -u)" -eq 0 ] && SUDO=""

# Source of truth for the grant line: the repo template if present, else the identical
# inline string (when this script ships inside the .app bundle, no template is alongside).
TEMPLATE="$SCRIPT_DIR/sleepless.sudoers.template"
if [ -f "$TEMPLATE" ]; then
  GRANT="$(sed "s/__USER__/$USER_NAME/" "$TEMPLATE")"
else
  GRANT="$USER_NAME ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"
fi

echo "Sleepless will install this passwordless grant at $SUDOERS_DST (root:wheel, 0440):"
echo ""
echo "    $GRANT"
echo ""
echo "It permits ONLY turning lid-close sleep on (1) or off (0). Nothing else."
if [ "${1:-}" != "--yes" ] && [ "${1:-}" != "-y" ]; then
  read -r -p "Continue? [y/N] " reply
  case "$reply" in [yY]*) ;; *) echo "Aborted."; exit 1 ;; esac
fi

TMP="$(mktemp)"
printf '%s\n' "$GRANT" > "$TMP"
if ! $SUDO visudo -cf "$TMP" >/dev/null; then
  echo "error: generated sudoers failed validation; not installing." >&2
  rm -f "$TMP"; exit 1
fi
$SUDO install -m 0440 -o root -g wheel "$TMP" "$SUDOERS_DST"
rm -f "$TMP"
$SUDO visudo -c >/dev/null && echo "✅ grant installed and sudoers parses cleanly ($SUDOERS_DST)."
echo "   Toggle Sleepless from the menu bar; it will no longer need a password."
