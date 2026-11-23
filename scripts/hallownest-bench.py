#!/usr/bin/env python3
"""Split assets/hallownest/bench.svg into one PNG per layer (same 320x220 canvas, rendered x4)
so the lock screen can animate them. Uses rsvg-convert, which honours the Inkscape blurs."""

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/hallownest/bench.svg"
OUT = ROOT / "assets/hallownest/bench"
LAYERS = ["banco", "cuerpo", "cabeza", "ojos"]
SCALE = 4


def main() -> None:
    svg = SRC.read_text()
    # Drop the hidden reference image, the guides and the template's placeholder seat
    svg = re.sub(r"<image\b[^>]*/>", "", svg, flags=re.S)
    svg = re.sub(r'<g\s+id="ayudas".*?</g>', "", svg, flags=re.S)
    svg = re.sub(r'<rect\b[^>]*id="rect1"[^>]*/>', "", svg, flags=re.S)
    OUT.mkdir(exist_ok=True)
    for layer in LAYERS:
        if f'id="{layer}"' not in svg:
            sys.exit(f"missing layer {layer}")
        hide = "".join(f"#{o}{{display:none}}" for o in LAYERS if o != layer)
        doc = svg.replace("</defs>", f"</defs><style>{hide}</style>", 1)
        png = OUT / f"{layer}.png"
        subprocess.run(["rsvg-convert", "-z", str(SCALE), "-o", str(png), "-"], input=doc.encode(), check=True)
        print(png.relative_to(ROOT))


if __name__ == "__main__":
    main()
