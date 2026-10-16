#!/usr/bin/env python3
"""Build terminal artwork from the wallpaper wordmarks and plasma tube.

Requires rsvg-convert and ImageMagick, like the wallpaper artwork workflow.
"""
from pathlib import Path
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "screensaver" / "art"
OUT.mkdir(parents=True, exist_ok=True)
NS = "{http://www.w3.org/2000/svg}"


def render(name, source, outline=False, caption=""):
    root = ET.parse(HERE / source).getroot()
    if source == "plasma-chamber.svg":
        path = next(p for p in root.iter(NS + "path") if p.get("id") == "loop")
        shape = f'<path d="{path.get("d")}" fill="none" stroke="white" stroke-width="15"/>'
        view = "1290 140 500 650"
        width, height = 38, 25
    else:
        for path in root.iter(NS + "path"):
            path.set("fill-rule", "evenodd")
            path.set("fill", "none" if outline else "white")
            if outline:
                path.set("stroke", "white")
                path.set("stroke-width", "8")
        shape = "".join(ET.tostring(p, encoding="unicode") for p in root.iter(NS + "path"))
        view = root.get("viewBox")
        width, height = (96, 15) if source.startswith("omarchy") else (72, 19)
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view}">{shape}</svg>'
    with tempfile.TemporaryDirectory() as tmp:
        png = Path(tmp) / "mask.png"
        subprocess.run(["rsvg-convert", "-w", str(width * 4), "-h", str(height * 8), "-o", str(png)], input=svg.encode(), check=True)
        pixels = subprocess.check_output(["magick", str(png), "-background", "black", "-alpha", "remove", "-resize", f"{width}x{height}!", "-colorspace", "gray", "-depth", "8", "txt:-"], text=True)
    rows = [[" "] * width for _ in range(height)]
    for line in pixels.splitlines():
        match = re.match(r"(\d+),(\d+): \((\d+)", line)
        if match:
            x, y, value = map(int, match.groups())
            if value >= 70:
                rows[y][x] = "█" if outline or source == "plasma-chamber.svg" else ["█", "▓", "▒"][y % 3]
    lines = ["".join(row).rstrip() for row in rows]
    if caption:
        lines += ["", caption.center(width).rstrip()]
    (OUT / (name + ".txt")).write_text("\n".join(lines) + "\n")


render("00-omarchy-synth-stripes", "omarchy-wordmark.svg")
render("01-plasma-chamber", "plasma-chamber.svg", caption="PLASMA 585 / NEON · 585 nm")
render("03-omarchy-amber-tubes", "omarchy-wordmark.svg", outline=True)
render("04-mbit-synth-stripes", "mbit-wordmark.svg", caption="MBI / NUS / SINGAPORE")
render("05-mbit-amber-tubes", "mbit-wordmark.svg", outline=True, caption="MBI / NUS / SINGAPORE")
