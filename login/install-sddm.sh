#!/usr/bin/env bash
#
# Install the Plasma 585 SDDM login theme. Run with sudo:
#
#   sudo ./login/install-sddm.sh
#
# Copies the QML greeter to /usr/local/share/sddm/themes/plasma-585 and selects
# it system-wide via /etc/sddm.conf.d/99-plasma-585.conf. Remove that one
# override file to restore the previous SDDM theme.

set -euo pipefail

if ((EUID != 0)); then
  echo "install-sddm.sh: run me with sudo" >&2
  exit 1
fi

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="/usr/local/share/sddm/themes/plasma-585"

mkdir -p "$DEST"
for item in Main.qml metadata.desktop theme.conf background.png; do
  [[ -e "$SRC/$item" ]] || continue
  install -Dm644 "$SRC/$item" "$DEST/$item"
done

install -Dm644 "$SRC/99-plasma-585.conf" /etc/sddm.conf.d/99-plasma-585.conf

echo "Installed the Plasma 585 SDDM theme. It appears on the next login."
