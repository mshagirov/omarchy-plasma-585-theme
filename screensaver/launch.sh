#!/usr/bin/env bash
# Reuse the installed launcher, changing only the terminal's runner argument.
set -euo pipefail
state="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/current"
stock="/usr/bin/omarchy-launch-screensaver"
if [[ $(cat "$state/theme.name" 2>/dev/null) != plasma-585 ]]; then
  exec "$stock" "$@"
fi
source=$(cat "$stock")
if [[ $source != *"-e omarchy-screensaver"* ]]; then
  echo "Omarchy's launcher changed; falling back to the stock screensaver." >&2
  exec "$stock" "$@"
fi
printf -v runner '%q' "$HOME/.config/omarchy/themes/plasma-585/screensaver/runner.sh"
source=${source//-e omarchy-screensaver/-e $runner}
# Do not use bash -c: its argv would contain the screensaver window class and
# match the stock launcher's own pgrep guard before any window was opened.
exec bash <(printf '%s\n' "$source") "$@"
