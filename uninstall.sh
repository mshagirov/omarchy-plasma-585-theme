#!/usr/bin/env bash
#
# Plasma 585 — uninstaller.
#
# Removes the theme, the four bundled plugins, and their references from
# shell.json, then restores the stock bar and re-enables the stock lock/polkit
# services. A backup of shell.json is written before any change.

set -euo pipefail

THEME_SLUG="plasma-585"
THEME_DIR="$HOME/.config/omarchy/themes/$THEME_SLUG"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"
SHELL_JSON="$HOME/.config/omarchy/shell.json"
STAMP="$(date +%Y%m%d-%H%M%S)"

command -v omarchy >/dev/null 2>&1 || {
  echo "uninstall.sh: the \`omarchy\` command was not found." >&2
  exit 1
}

log() { printf '\033[38;5;215m==>\033[0m %s\n' "$*"; }

if [[ -f "$SHELL_JSON" ]] && command -v jq >/dev/null 2>&1; then
  cp "$SHELL_JSON" "$SHELL_JSON.plasma585-uninstall-$STAMP"
  log "Backed up shell.json -> $(basename "$SHELL_JSON").plasma585-uninstall-$STAMP"
  tmp="$(mktemp)"
  jq '
    .bar.id = (if .bar.id == "plasma585.bar" then "omarchy.bar" else .bar.id end)
    | (.bar.layout | objects) |= with_entries(
        .value = [.value[] | select(.id != "plasma585.workspaces")])
    | .plugins = [(.plugins // [])[] | select(.id != "plasma585.lock" and .id != "plasma585.polkit")]
    | .disabledPlugins = [(.disabledPlugins // [])[] | select(. != "omarchy.lock" and . != "omarchy.polkit" and (. | startswith("plasma585.") | not))]
    | .cloneSourceRestores = [(.cloneSourceRestores // [])[] | select(. != "plasma585.lock" and . != "plasma585.polkit")]
    | if (.cloneSourceRestores | length) == 0 then del(.cloneSourceRestores) else . end
  ' "$SHELL_JSON" >"$tmp"
  mv "$tmp" "$SHELL_JSON"
fi

for suffix in bar workspaces lock polkit; do
  rm -rf "$PLUGINS_DIR/plasma585.$suffix"
done
log "Removed bundled plugins"

rm -rf "$THEME_DIR"
log "Removed $THEME_DIR"

if pgrep -x omarchy-shell >/dev/null 2>&1; then
  omarchy restart shell || true
fi

log "Done. Apply any other theme with: omarchy theme list && omarchy theme set <name>"
