#!/usr/bin/env bash
#
# Plasma 585 — installer for Omarchy
#
# Installs the theme into ~/.config/omarchy/themes/plasma-585, installs the four
# bundled shell plugins (bar, workspaces, lock, polkit), enables them, applies
# the recommended bar layout, and activates the theme.
#
# Usage:
#   ./install.sh              install theme + plugins + recommended layout
#   ./install.sh --no-layout  keep your current bar layout
#   ./install.sh --plugins-only
#   ./install.sh --theme-only
#
# The theme is copied (not cloned) so its custom hyprland.lua — the amber edge
# shadow and rounding — survives. Omarchy drops Lua from themes installed with
# `omarchy theme install`, which would silently lose that styling.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SLUG="plasma-585"
THEME_DISPLAY_NAME="Plasma 585"
THEME_DIR="$HOME/.config/omarchy/themes/$THEME_SLUG"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"
SHELL_JSON="$HOME/.config/omarchy/shell.json"
STAMP="$(date +%Y%m%d-%H%M%S)"

THEME_ITEMS=(
  colors.toml shell.toml hyprland.lua icons.theme
  backgrounds artwork login
  bar-plugin workspaces-plugin lock-plugin polkit-plugin
)
PLUGIN_SUFFIXES=(bar workspaces lock polkit)

INSTALL_THEME=1
INSTALL_PLUGINS=1
APPLY_LAYOUT=1

usage() {
  sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while (($# > 0)); do
  case "$1" in
  --no-layout) APPLY_LAYOUT=0 ;;
  --plugins-only) INSTALL_THEME=0 ;;
  --theme-only) INSTALL_PLUGINS=0; APPLY_LAYOUT=0 ;;
  -h | --help) usage; exit 0 ;;
  *)
    echo "install.sh: unknown option: $1" >&2
    usage
    exit 2
    ;;
  esac
  shift
done

if ! command -v omarchy >/dev/null 2>&1; then
  cat >&2 <<'EOF'
install.sh: the `omarchy` command was not found.

Plasma 585 is an Omarchy theme. Install Omarchy first
(https://omarchy.org), then re-run this script on the machine.
EOF
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "install.sh: jq is required (omarchy includes it). Install jq and re-run." >&2
  exit 1
fi

log() { printf '\033[38;5;215m==>\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- theme files
if ((INSTALL_THEME)); then
  log "Installing theme files to $THEME_DIR"
  mkdir -p "$THEME_DIR"
  for item in "${THEME_ITEMS[@]}"; do
    [[ -e "$REPO_DIR/$item" ]] || continue
    rm -rf "$THEME_DIR/$item"
    cp -R "$REPO_DIR/$item" "$THEME_DIR/$item"
  done
fi

# ------------------------------------------------------------------- plugins
if ((INSTALL_PLUGINS)); then
  log "Installing shell plugins into $PLUGINS_DIR"
  mkdir -p "$PLUGINS_DIR"
  for suffix in "${PLUGIN_SUFFIXES[@]}"; do
    src="$REPO_DIR/$suffix-plugin"
    dest="$PLUGINS_DIR/plasma585.$suffix"
    [[ -d "$src" ]] || continue
    rm -rf "$dest"
    cp -R "$src" "$dest"
  done
fi

# -------------------------------------------------------------- shell config
if ((INSTALL_PLUGINS || APPLY_LAYOUT)); then
  if [[ ! -f "$SHELL_JSON" ]]; then
    default_shell="$OMARCHY_PATH/config/omarchy/shell.json"
    if [[ -n "${OMARCHY_PATH:-}" && -f "$default_shell" ]]; then
      mkdir -p "$(dirname "$SHELL_JSON")"
      cp "$default_shell" "$SHELL_JSON"
    else
      mkdir -p "$(dirname "$SHELL_JSON")"
      printf '{}\n' >"$SHELL_JSON"
    fi
  fi

  cp "$SHELL_JSON" "$SHELL_JSON.plasma585-backup-$STAMP"
  log "Backed up shell.json -> $(basename "$SHELL_JSON").plasma585-backup-$STAMP"

  tmp="$(mktemp)"
  if ((APPLY_LAYOUT)); then
    jq --slurpfile layout "$REPO_DIR/bar-layout.json" '
      .bar = $layout[0].bar
      | .plugins = (((.plugins // [])
          | map(select(.id != "plasma585.lock" and .id != "plasma585.polkit"
                       and .id != "omarchy.lock" and .id != "omarchy.polkit")))
          + [{"id": "plasma585.lock"}, {"id": "plasma585.polkit"}])
      | .disabledPlugins = (((.disabledPlugins // [])
          + ["omarchy.lock", "omarchy.polkit"]) | unique)
      | .cloneSourceRestores = (((.cloneSourceRestores // [])
          + ["plasma585.lock", "plasma585.polkit"]) | unique)
      | .version = (.version // 1)
    ' "$SHELL_JSON" >"$tmp"
  else
    jq '
      .plugins = (((.plugins // [])
          | map(select(.id != "plasma585.lock" and .id != "plasma585.polkit"
                       and .id != "omarchy.lock" and .id != "omarchy.polkit")))
          + [{"id": "plasma585.lock"}, {"id": "plasma585.polkit"}])
      | .disabledPlugins = (((.disabledPlugins // [])
          + ["omarchy.lock", "omarchy.polkit"]) | unique)
      | .cloneSourceRestores = (((.cloneSourceRestores // [])
          + ["plasma585.lock", "plasma585.polkit"]) | unique)
      | .version = (.version // 1)
    ' "$SHELL_JSON" >"$tmp"
  fi
  mv "$tmp" "$SHELL_JSON"

  if command -v omarchy-shell >/dev/null 2>&1; then
    timeout 5 omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  fi
fi

# --------------------------------------------------------------------- apply
log "Activating $THEME_DISPLAY_NAME"
omarchy theme set "$THEME_DISPLAY_NAME"

if ((INSTALL_PLUGINS)) && pgrep -x omarchy-shell >/dev/null 2>&1; then
  log "Restarting the shell to load the plugins"
  omarchy restart shell || true
fi

log "Done."
cat <<EOF

  Theme:    $THEME_DISPLAY_NAME
  Location: $THEME_DIR
  Plugins:  $PLUGINS_DIR/plasma585.{bar,workspaces,lock,polkit}

Optional — match the login screen (needs admin rights):

  sudo "$REPO_DIR/login/install-sddm.sh"

Uninstall with "$REPO_DIR/uninstall.sh"
EOF
