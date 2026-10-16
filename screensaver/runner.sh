#!/usr/bin/env bash
# User-local override: keep Omarchy's launcher, terminal and random TTE effects.
set -u

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/current"
if [[ $(cat "$STATE/theme.name" 2>/dev/null) != plasma-585 ]]; then
  exec /usr/bin/omarchy-screensaver "$@"
fi

shopt -s nullglob
art=("$STATE/theme/screensaver/art/"*.txt)
if ((${#art[@]} == 0)); then
  exec /usr/bin/omarchy-screensaver "$@"
fi

child=""
cleanup() {
  trap - INT TERM HUP QUIT
  if [[ -n $child ]]; then
    kill "$child" 2>/dev/null || true
    wait "$child" 2>/dev/null || true
  fi
  hyprctl eval 'hl.config({ cursor = { invisible = false } })' &>/dev/null ||
    hyprctl keyword cursor:invisible false &>/dev/null || true
  pkill -f '[o]rg.omarchy.screensaver' 2>/dev/null || true
  exit 0
}
trap cleanup INT TERM HUP QUIT

printf '\033]11;rgb:00/00/00\007'
hyprctl eval 'hl.config({ cursor = { invisible = true } })' &>/dev/null ||
  hyprctl keyword cursor:invisible true &>/dev/null || true
deadline=$((SECONDS + 2))
while ((SECONDS < deadline)) && [[ $(stty size 2>/dev/null) == "24 80" ]]; do
  sleep 0.02
done

index=0
while true; do
  ttfx -i "${art[index]}" \
    --frame-rate 120 --canvas-width 0 --canvas-height 0 --reuse-canvas \
    --anchor-canvas c --anchor-text c --random-effect --no-eol --no-restore-cursor &
  child=$!
  while kill -0 "$child" 2>/dev/null; do
    if read -r -n1 -t 1 || ! hyprctl activewindow -j | jq -e '.class == "org.omarchy.screensaver"' >/dev/null 2>&1; then
      cleanup
    fi
  done
  wait "$child"
  status=$?
  child=""
  ((status == 0)) || cleanup
  index=$(((index + 1) % ${#art[@]}))
done
