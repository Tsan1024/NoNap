#!/usr/bin/env bash
# install.sh — build NoNap, install it to /Applications, add the passwordless
# grant that lets it toggle lid-close sleep, and (optionally) start it at login.
#
# This is the ONLY script that touches sudo. It tells you exactly what it will write
# before it writes it. To back everything out, run ./uninstall.sh.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="NoNap"
APP="/Applications/$APP_NAME.app"
SUDOERS_DST="/etc/sudoers.d/nonap-disablesleep"
USER_NAME="$(id -un)"

echo "NoNap installer"
echo "==================="
echo "This will:"
echo "  1. Build $APP_NAME.app and copy it to /Applications."
echo "  2. Install a passwordless sudo grant at $SUDOERS_DST so the app can flip"
echo "     lid-close sleep without prompting. The grant (root:wheel, 0440) is EXACTLY:"
echo ""
echo "       $USER_NAME ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"
echo ""
echo "     That is the only thing it permits — turn lid-close sleep on or off. Nothing else."
echo "  3. Launch the app. Login startup remains optional in the app."
echo ""
read -r -p "Continue? [y/N] " reply
case "$reply" in [yY]*) ;; *) echo "Aborted."; exit 1 ;; esac

# 1. Build into /Applications.
echo "==> Building into /Applications"
DEST=/Applications "$REPO/build.sh" /Applications

# 2. Passwordless grant (delegated to grant.sh, the single source of truth).
echo "==> Installing passwordless grant (you'll be asked for your password once)"
"$REPO/grant.sh" --yes

# 3. Launch now. The native in-app switch owns the optional login item.
open "$APP"

echo ""
echo "✅ Installed. The coffee cup is in your menu bar — click it to toggle."
echo "   Turn ON, close the lid: your Mac stays awake on battery (auto-off at the floor you set)."
echo "   To remove everything (including the grant): ./macos/uninstall.sh"
