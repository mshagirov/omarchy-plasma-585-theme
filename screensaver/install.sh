#!/usr/bin/env bash
# Clone the idle plugin, keeping its timers and locking behavior unchanged.
set -euo pipefail
directory="$HOME/.config/omarchy/themes/plasma-585/screensaver"
plugin="$HOME/.config/omarchy/plugins/${USER:-$(id -un)}.idle"
if [[ ! -f $directory/runner.sh ]]; then
  echo "Install the Plasma 585 theme before enabling its screensaver." >&2
  exit 1
fi
if [[ -e $plugin ]]; then
  if [[ ! -f $plugin/.plasma585-screensaver ]]; then
    echo "Refusing to replace existing idle plugin: $plugin" >&2
    exit 1
  fi
else
  if [[ -f $HOME/.config/omarchy/shell.json ]]; then
    cp "$HOME/.config/omarchy/shell.json" "$HOME/.config/omarchy/shell.json.plasma585-screensaver-$(date +%Y%m%d-%H%M%S).bak"
  fi
  omarchy plugin clone omarchy.idle
  touch "$plugin/.plasma585-screensaver"
fi
python - "$plugin/Service.qml" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
source = path.read_text()
launcher = "bash ~/.config/omarchy/themes/plasma-585/screensaver/launch.sh"
if "omarchy-launch-screensaver" not in source and launcher not in source:
    raise SystemExit("Unrecognized idle plugin: screensaver launch left unchanged")
path.write_text(source.replace("omarchy-launch-screensaver", launcher))
PY
chmod +x "$directory/runner.sh" "$directory/launch.sh"
echo "Plasma 585 screensaver enabled (other themes use stock Omarchy)."
