#!/usr/bin/env python3
"""Isolated checks; never launch a desktop terminal or touch user settings."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

HERE = Path(__file__).resolve().parent


class ScreensaverTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.bin = self.home / ".local/bin"
        self.bin.mkdir(parents=True)
        self.env = dict(os.environ, HOME=str(self.home), USER="testuser", XDG_STATE_HOME=str(self.home / "state"))
        self.env["PATH"] = str(self.bin) + ":" + os.environ["PATH"]

    def script(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/bash\n" + body)
        path.chmod(0o755)
        return path

    def test_install_is_idempotent_and_preserves_other_overrides(self):
        target = self.home / ".config/omarchy/themes/plasma-585/screensaver/runner.sh"
        target.parent.mkdir(parents=True)
        target.write_text("#!/bin/bash\n")
        (target.parent / "launch.sh").write_text("#!/bin/bash\n")
        self.script("omarchy", '''
mkdir -p "$HOME/.config/omarchy/plugins/$USER.idle"
echo 'runProcess("omarchy-launch-screensaver")' > "$HOME/.config/omarchy/plugins/$USER.idle/Service.qml"
''')
        for _ in range(2):
            subprocess.run(["bash", str(HERE / "install.sh")], env=self.env, check=True, capture_output=True)
        plugin = self.home / ".config/omarchy/plugins/testuser.idle"
        override = plugin / "Service.qml"
        self.assertIn("screensaver/launch.sh", override.read_text())
        (plugin / ".plasma585-screensaver").unlink()
        override.write_text("my custom runner\n")
        result = subprocess.run(["bash", str(HERE / "install.sh")], env=self.env, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(override.read_text(), "my custom runner\n")

    def test_cycles_through_all_artworks_with_regular_effects(self):
        state = self.home / "state/omarchy/current"
        art = state / "theme/screensaver/art"
        art.mkdir(parents=True)
        (state / "theme.name").write_text("plasma-585\n")
        originals = sorted((HERE / "art").glob("*.txt"))
        self.assertEqual(len(originals), 5)
        for source in originals:
            (art / source.name).write_text(source.read_text())
        self.script("hyprctl", 'echo \'{"class":"org.omarchy.screensaver"}\'\n')
        self.script("stty", 'echo "50 160"\n')
        self.script("pkill", "exit 0\n")
        self.script("ttfx", '''
echo "$*" >> "$HOME/calls"
count=$(wc -l < "$HOME/calls")
if ((count > 5)); then exit 1; fi
sleep 0.02
''')
        subprocess.run(["bash", str(HERE / "runner.sh")], env=self.env, stdin=subprocess.DEVNULL,
                       stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=10, check=True)
        calls = (self.home / "calls").read_text().splitlines()
        self.assertEqual(len(calls), 6)
        for index, call in enumerate(calls):
            self.assertIn(originals[index % 5].name, call)
            self.assertIn("--random-effect", call)
            self.assertIn("--reuse-canvas", call)

    @unittest.skipUnless(Path("/usr/bin/omarchy-launch-screensaver").exists(), "requires Omarchy launcher")
    def test_launcher_passes_custom_runner_to_standard_terminal(self):
        state = self.home / "state/omarchy/current"
        state.mkdir(parents=True)
        (state / "theme.name").write_text("plasma-585\n")
        self.env.update(XDG_RUNTIME_DIR=str(self.home), HYPRLAND_INSTANCE_SIGNATURE="test", OMARCHY_PATH="/usr/share/omarchy")
        self.script("pgrep", "exit 1\n")
        self.script("omarchy-toggle-enabled", "exit 1\n")
        self.script("omarchy-hyprland-monitor-focused", "echo MON1\n")
        self.script("xdg-terminal-exec", "echo foot\n")
        self.script("socat", "echo 'openwindow>>123,MON1,org.omarchy.screensaver,test'\n")
        self.script("hyprctl", '''
echo "$*" >> "$HOME/hypr-calls"
case "$1" in
  monitors) echo '[{"name":"MON1","specialWorkspace":{"name":""}}]' ;;
  clients) echo '[]' ;;
esac
''')
        subprocess.run(["bash", str(HERE / "launch.sh"), "force"], env=self.env,
                       stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=10, check=True)
        calls = (self.home / "hypr-calls").read_text()
        self.assertIn("screensaver/runner.sh", calls)
        self.assertIn("foot", calls)
        self.assertIn("org.omarchy.screensaver", calls)


if __name__ == "__main__":
    unittest.main()
