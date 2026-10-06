#!/usr/bin/env python3
"""Render Plasma 585's two alternate 4K wallpapers from Omarchy's wordmark."""
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
THEME = HERE.parent
source = HERE / "omarchy-wordmark.svg"
logo = ET.parse(source).getroot()
paths = "".join(
    '<path d="' + p.attrib["d"] + '" fill-rule="evenodd"/>'
    for p in logo.iter("{http://www.w3.org/2000/svg}path")
)
defs = f'''<defs>
 <g id="logo">{paths}</g>
 <clipPath id="letters">{paths}</clipPath>
 <radialGradient id="ground"><stop stop-color="#22201c"/><stop offset=".55" stop-color="#101010"/><stop offset="1" stop-color="#050505"/></radialGradient>
 <filter id="wide" x="-20%" y="-80%" width="140%" height="260%"><feGaussianBlur stdDeviation="18"/></filter>
 <filter id="near" x="-10%" y="-40%" width="120%" height="180%"><feGaussianBlur stdDeviation="4"/></filter>
 <linearGradient id="tube" x2="0" y2="1"><stop stop-color="#ffe0a0"/><stop offset=".5" stop-color="#ffb85a"/><stop offset="1" stop-color="#d88736"/></linearGradient>
 <pattern id="scan" width="4" height="4" patternUnits="userSpaceOnUse"><path d="M0 0H4" stroke="#000" opacity=".09"/></pattern>
</defs>'''
colors = ["#ddd0aa", "#e3bd64", "#e5a04a", "#e98437", "#ce6934", "#a95232", "#607c46", "#49623c", "#526f79", "#d3c8ae"]
bands = "".join(f'<rect x="0" y="{i * 28.5}" width="1215" height="24.5" fill="{color}"/>' for i, color in enumerate(colors))
striped = f'''<use href="#logo" fill="none" stroke="#fca748" stroke-width="9" opacity=".32" filter="url(#wide)"/>
<use href="#logo" fill="none" stroke="#ffb85a" stroke-width="3" opacity=".55" filter="url(#near)"/>
<g clip-path="url(#letters)">{bands}</g>
<use href="#logo" fill="none" stroke="#ffd28a" stroke-width=".75" opacity=".6"/>'''
tubes = '''<use href="#logo" fill="none" stroke="#f68a29" stroke-width="16" opacity=".5" filter="url(#wide)"/>
<use href="#logo" fill="none" stroke="#ffad46" stroke-width="7" opacity=".85" filter="url(#near)"/>
<use href="#logo" fill="#100d09" stroke="#593219" stroke-width="7"/>
<use href="#logo" fill="none" stroke="url(#tube)" stroke-width="3.2"/>
<use href="#logo" fill="none" stroke="#ffe1a2" stroke-width=".85"/>'''
for name, art, label in [
    ("00-omarchy-synth-stripes", striped, "RHYTHM / POLYPHONIC"),
    ("03-omarchy-amber-tubes", tubes, "AMBER / DISCHARGE"),
]:
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="3840" height="2160" viewBox="0 0 1920 1080">
{defs}<rect width="1920" height="1080" fill="url(#ground)"/>
<g transform="translate(352.5 397.5)">{art}</g>
<text x="960" y="773" text-anchor="middle" font-family="monospace" font-size="9" letter-spacing="4" fill="#91704a" opacity=".6">PLASMA 585 / {label}</text>
<rect width="1920" height="1080" fill="url(#scan)"/></svg>'''
    svg_path = HERE / (name + ".svg")
    svg_path.write_text(svg)
    subprocess.run(["rsvg-convert", str(svg_path), "-o", str(THEME / "backgrounds" / (name + ".png"))], check=True)
