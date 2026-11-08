#!/usr/bin/env python3
"""Converts the Windows Hollow Knight cursor set (assets/cursors/hollow-knight) into an Xcursor theme.

Writes ~/.local/share/icons/HollowKnight/: Xcursor files (cursors/ + aliases) for apps, and a
hyprcursor build (hyprcursors/ + manifest.hl) that Hyprland prefers; the latter needs
hyprcursor-util. The sources are 32 px pixel art, so bigger sizes use nearest-neighbour scaling.

A cursor redrawn as SVG in assets/cursors/hollow-knight/svg/ (<name>.svg, or <name>-<frame>.svg for
the animated ones) replaces its pixel art: hyprcursor gets the SVG itself and Xcursor gets it
rendered at every size (rsvg-convert + magick). The layers with id "referencia" and "ayudas" are
dropped first.

Usage: python3 scripts/hallownest-cursors.py              # build and install the theme
       python3 scripts/hallownest-cursors.py --templates  # Inkscape templates for the missing SVGs
       python3 scripts/hallownest-cursors.py --vectorize  # auto-trace every SVG still empty (potrace)
"""

import base64
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / "assets/cursors/hollow-knight"
SVG_DIR = SRC / "svg"
SVG_NS = "http://www.w3.org/2000/svg"
DST = Path.home() / ".local/share/icons/HollowKnight"
SIZES = (24, 32, 48, 64, 96)

# Windows role -> Xcursor names (first is the real file, the rest are symlinks)
NAMES = {
    "Normal.cur": ["default", "left_ptr", "arrow", "top_left_arrow", "context-menu", "copy", "alias",
                   "dnd-move", "dnd-copy", "dnd-link", "dnd-none", "zoom-in", "zoom-out", "vertical-text"],
    "Link.cur": ["pointer", "hand1", "hand2", "pointing_hand", "grab", "openhand"],
    "Unavaliable.cur": ["not-allowed", "no-drop", "crossed_circle", "forbidden", "circle", "dnd-no-drop"],
    "Precision.cur": ["crosshair", "cross", "tcross", "cell", "plus"],
    "Working.ani": ["progress", "left_ptr_watch", "half-busy"],
    "Busy.ani": ["wait", "watch"],
    "Handwriting.cur": ["pencil"],
    "Text.cur": ["text", "xterm", "ibeam"],
    "Help.cur": ["help", "question_arrow", "whats_this", "left_ptr_help"],
    "Alternate.cur": ["up-arrow", "up_arrow", "center_ptr"],
    "Vertical.cur": ["ns-resize", "size_ver", "sb_v_double_arrow", "v_double_arrow", "n-resize", "s-resize",
                     "row-resize", "top_side", "bottom_side", "split_v"],
    "Horizontal.cur": ["ew-resize", "size_hor", "sb_h_double_arrow", "h_double_arrow", "e-resize", "w-resize",
                       "col-resize", "left_side", "right_side", "split_h"],
    "Diagonal 1.cur": ["nwse-resize", "size_fdiag", "bd_double_arrow", "nw-resize", "se-resize",
                       "top_left_corner", "bottom_right_corner"],
    "Diagonal 2.cur": ["nesw-resize", "size_bdiag", "fd_double_arrow", "ne-resize", "sw-resize",
                       "top_right_corner", "bottom_left_corner"],
    "Move.cur": ["move", "all-scroll", "fleur", "size_all", "grabbing", "closedhand", "dnd-ask"],
}


def read_cur(data: bytes):
    """First image of a .cur: (width, height, hot_x, hot_y, ARGB rows top-down)."""
    _, kind, count = struct.unpack_from("<HHH", data)
    assert kind == 2 and count >= 1, "not a cursor"
    w, h, _, _, hx, hy, _, offset = struct.unpack_from("<BBBBHHII", data, 6)
    w, h = w or 256, h or 256
    _, _, bh, _, bpp = struct.unpack_from("<IiiHH", data, offset)
    assert bpp == 32 and abs(bh) == h * 2, f"unsupported bitmap ({bpp} bpp)"
    pixels = data[offset + 40:offset + 40 + w * h * 4]
    rows = [pixels[y * w * 4:(y + 1) * w * 4] for y in range(h)][::-1]  # BMP is bottom-up
    argb = [[struct.unpack_from("<I", row, x * 4)[0] for x in range(w)] for row in rows]
    return w, h, hx, hy, argb


def read_ani(data: bytes):
    """Frames of a .ani in play order and the delay of each in ms."""
    assert data[:4] == b"RIFF" and data[8:12] == b"ACON"
    frames, rates, seq, jiffies = [], None, None, 6
    i = 12
    while i + 8 <= len(data):
        cid, size = data[i:i + 4], struct.unpack_from("<I", data, i + 4)[0]
        body = data[i + 8:i + 8 + size]
        if cid == b"LIST":
            i += 12
            continue
        if cid == b"anih":
            jiffies = struct.unpack_from("<I", body, 28)[0] or 6
        elif cid == b"rate":
            rates = list(struct.unpack(f"<{size // 4}I", body))
        elif cid == b"seq ":
            seq = list(struct.unpack(f"<{size // 4}I", body))
        elif cid == b"icon":
            frames.append(read_cur(body))
        i += 8 + size + (size & 1)
    order = seq or list(range(len(frames)))
    return [(frames[f], round((rates[n] if rates else jiffies) * 1000 / 60)) for n, f in enumerate(order)]


def premultiply(p: int) -> int:
    a = p >> 24
    r, g, b = (p >> 16) & 255, (p >> 8) & 255, p & 255
    return (a << 24) | (r * a // 255 << 16) | (g * a // 255 << 8) | (b * a // 255)


def scale(img, size: int):
    w, h, hx, hy, argb = img
    k = size / w
    out = [[premultiply(argb[int(y / k)][int(x / k)]) for x in range(size)] for y in range(round(h * k))]
    return size, len(out), min(size - 1, round(hx * k)), min(len(out) - 1, round(hy * k)), out


def svg_file(name: str, frame: int, count: int) -> Path:
    return SVG_DIR / (f"{name}-{frame}.svg" if count > 1 else f"{name}.svg")


def clean_svg(path: Path) -> bytes:
    """The drawing without the reference and helper layers."""
    ET.register_namespace("", SVG_NS)
    tree = ET.parse(path)
    root = tree.getroot()
    for g in list(root):
        if g.get("id") in ("referencia", "ayudas"):
            root.remove(g)
    return ET.tostring(root)


def render(svg: bytes, img, size: int):
    """SVG rendered at size, with the pixel-art cursor's hotspot scaled to it."""
    w, h, hx, hy, _ = img
    page = subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size)], input=svg, capture_output=True, check=True).stdout
    rgba = subprocess.run(["magick", "png:-", "-depth", "8", "rgba:-"], input=page, capture_output=True, check=True).stdout
    px = [[premultiply(a << 24 | r << 16 | g << 8 | b) for r, g, b, a in (rgba[i:i + 4] for i in range(y * size * 4, (y + 1) * size * 4, 4))] for y in range(size)]
    k = size / w
    return size, size, min(size - 1, round(hx * k)), min(size - 1, round(hy * k)), px


def xcursor(frames, svgs) -> bytes:
    """frames: [(image, delay_ms)], svgs: the frames' clean SVGs or None -> Xcursor file."""
    chunks = []
    for size in SIZES:
        for (img, delay), svg in zip(frames, svgs or [None] * len(frames)):
            w, h, hx, hy, px = render(svg, img, size) if svg else scale(img, size)
            header = struct.pack("<9I", 36, 0xFFFD0002, size, 1, w, h, hx, hy, delay)
            chunks.append((size, header + b"".join(struct.pack("<I", p) for row in px for p in row)))
    pos = 16 + 12 * len(chunks)
    toc = b""
    for size, chunk in chunks:
        toc += struct.pack("<3I", 0xFFFD0002, size, pos)
        pos += len(chunk)
    return struct.pack("<4sIII", b"Xcur", 16, 0x10000, len(chunks)) + toc + b"".join(c for _, c in chunks)


def png(img) -> bytes:
    w, h, _, _, argb = img
    raw = b"".join(b"\0" + b"".join(struct.pack(">I", (p << 8 | p >> 24) & 0xFFFFFFFF) for p in row) for row in argb)

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))

    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")


def hyprcursor(themes: dict) -> None:
    """themes: {name: (frames, aliases)}; builds with hyprcursor-util into DST."""
    if not shutil.which("hyprcursor-util"):
        print("hyprcursor-util not found: only Xcursor was written")
        return
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "src"
        (src / "hyprcursors").mkdir(parents=True)
        (src / "manifest.hl").write_text("name = HollowKnight\ndescription = Hollow Knight cursors by Newty\nversion = 1\ncursors_directory = hyprcursors\n")
        for name, (frames, aliases, svgs) in themes.items():
            shape = src / "hyprcursors" / name
            shape.mkdir()
            w, h, hx, hy, _ = frames[0][0]
            meta = [f"resize_algorithm = {'bilinear' if svgs else 'nearest'}", f"hotspot_x = {hx / w:.4f}", f"hotspot_y = {hy / h:.4f}", "nominal_size = 1.0"]
            meta += [f"define_override = {a}" for a in aliases]
            for n, (img, delay) in enumerate(frames):
                if svgs:
                    (shape / f"{n}.svg").write_bytes(svgs[n])
                    meta.append(f"define_size = 0, {n}.svg" + (f", {delay}" if delay else ""))
                else:
                    (shape / f"{n}.png").write_bytes(png(img))
                    meta.append(f"define_size = {w}, {n}.png" + (f", {delay}" if delay else ""))
            (shape / "meta.hl").write_text("\n".join(meta) + "\n")
        out = Path(tmp) / "out"
        out.mkdir()
        res = subprocess.run(["hyprcursor-util", "--create", str(src), "--output", str(out)], capture_output=True, text=True)
        if res.returncode != 0:
            raise SystemExit(f"hyprcursor-util failed:\n{res.stdout}{res.stderr}")
        built = next(out.iterdir())
        shutil.rmtree(DST / "hyprcursors", ignore_errors=True)
        shutil.copytree(built / "hyprcursors", DST / "hyprcursors")
        shutil.copy(next(built.glob("manifest.*")), DST)


def lum(rgb: int) -> float:
    return 0.299 * (rgb >> 16 & 255) + 0.587 * (rgb >> 8 & 255) + 0.114 * (rgb & 255)


def tones(pixels: list, k: int = 4) -> list:
    """Grey levels of the solid pixels (1D k-means, close levels merged): [(lowest lum, colour)]."""
    rgbs = [p & 0xFFFFFF for p in pixels]
    levels = sorted({round(lum(p)) for p in rgbs})
    centres = [levels[int(i * (len(levels) - 1) / max(1, k - 1))] for i in range(k)]
    for _ in range(20):
        groups = [[] for _ in centres]
        for p in rgbs:
            groups[min(range(len(centres)), key=lambda i: abs(lum(p) - centres[i]))].append(p)
        centres = [sum(map(lum, g)) / len(g) if g else c for g, c in zip(groups, centres)]
    merged = []
    for c, g in sorted(zip(centres, groups)):
        if not g:
            continue
        if merged and c - merged[-1][0] < 35:
            merged[-1] = (merged[-1][0], merged[-1][1] + g)
        else:
            merged.append((c, g))
    return [(min(map(lum, g)), "#" + "".join(f"{sum(p >> s & 255 for p in g) // len(g):02x}" for s in (16, 8, 0))) for _, g in merged]


def trace(mask: list, w: int, h: int) -> str:
    """potrace path of a boolean mask, in the cursor's own pixel coordinates."""
    # A smooth 8x upscale before tracing keeps 1 px strokes as strokes instead of blobs
    pgm = f"P5\n{w} {h}\n255\n".encode() + bytes(0 if m else 255 for row in mask for m in row)
    pbm = subprocess.run(["magick", "pgm:-", "-filter", "Catrom", "-resize", "800%", "-threshold", "50%", "pbm:-"], input=pgm, capture_output=True, check=True).stdout
    svg = subprocess.run(["potrace", "-b", "svg", "-r", "576", "-t", "4", "-a", "1", "-O", "0.4", "-o", "-", "-"], input=pbm, capture_output=True, check=True).stdout.decode()
    group = re.search(r'<g transform="([^"]*)"[^>]*>(.*?)</g>', svg, re.S)
    paths = re.findall(r'd="([^"]*)"', group.group(2))
    return f'transform="{group.group(1)}" d="{" ".join(paths)}"' if paths else ""


def vectorize(img) -> str:
    """Stacked dark-to-light traced layers, plus the faint halo as a shadow or glow filter."""
    w, h, _, _, argb = img
    flat = [p for row in argb for p in row]
    out = []
    for i, (low, colour) in enumerate(tones([p for p in flat if p >> 24 >= 150])):
        mask = [[p >> 24 >= 150 and (i == 0 or lum(p & 0xFFFFFF) >= low) for p in row] for row in argb]
        path = trace(mask, w, h)
        if path:
            out.append(f'<path fill="{colour}" {path} />')
    soft = [p for p in flat if 0 < p >> 24 < 150]
    if not soft:
        return "".join(out)
    glow = sum(lum(p & 0xFFFFFF) > 128 for p in soft) > len(soft) / 2
    effect = ('<feDropShadow dx="0" dy="0" stdDeviation="0.9" flood-color="#ffffff" flood-opacity="0.6" />' if glow
              else '<feDropShadow dx="0.6" dy="0.8" stdDeviation="0.7" flood-color="#000000" flood-opacity="0.45" />')
    return f'<defs><filter id="halo" x="-30%" y="-30%" width="160%" height="160%">{effect}</filter></defs><g filter="url(#halo)">{"".join(out)}</g>'


EMPTY_LAYER = '<g inkscape:groupmode="layer" id="cursor" inkscape:label="Cursor" />'


def template(img, title: str, drawing: str = "") -> str:
    w, h, hx, hy, _ = img
    ref = base64.b64encode(png(img)).decode()
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!--
  Cursor "{title}" de Hollow Knight, para redibujar en vector (lienzo {w} x {h}, no lo cambies).
  1. Dibuja en la capa "Cursor" calcando la capa "Referencia" (el pixel art original, bloqueada).
  2. La capa "Ayudas" marca en rojo el punto activo (hotspot): la punta del cursor debe caer ahi.
  3. Guarda como SVG de Inkscape con este mismo nombre y ejecuta
     python3 scripts/hallownest-cursors.py (las capas Referencia y Ayudas se quitan solas).
  Borra el archivo para volver al pixel art.
-->
<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" version="1.1" xmlns="{SVG_NS}"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd">
  <sodipodi:namedview id="namedview" pagecolor="#2a2d35" inkscape:pageopacity="1" inkscape:zoom="20"
     inkscape:cx="{w / 2}" inkscape:cy="{h / 2}" inkscape:current-layer="cursor" showgrid="true">
    <inkscape:grid id="grid" type="xygrid" units="px" spacingx="1" spacingy="1" empspacing="8"
       color="#9ba4b5" opacity="0.08" empcolor="#9ba4b5" empopacity="0.2" />
  </sodipodi:namedview>
  <g inkscape:groupmode="layer" id="referencia" inkscape:label="Referencia" sodipodi:insensitive="true" opacity="0.5">
    <image width="{w}" height="{h}" style="image-rendering:pixelated" href="data:image/png;base64,{ref}" />
  </g>
  {f'<g inkscape:groupmode="layer" id="cursor" inkscape:label="Cursor">{drawing}</g>' if drawing else EMPTY_LAYER}
  <g inkscape:groupmode="layer" id="ayudas" inkscape:label="Ayudas" sodipodi:insensitive="true">
    <path d="M {hx + 0.5 - 2},{hy + 0.5} h 4 M {hx + 0.5},{hy + 0.5 - 2} v 4" stroke="#e63946" stroke-width="0.25" />
    <circle cx="{hx + 0.5}" cy="{hy + 0.5}" r="0.6" fill="none" stroke="#e63946" stroke-width="0.2" />
  </g>
</svg>
"""


def templates(traced: bool) -> None:
    """Writes missing templates; traced also fills the ones whose Cursor layer is still empty."""
    SVG_DIR.mkdir(exist_ok=True)
    made = 0
    for src, names in NAMES.items():
        data = (SRC / src).read_bytes()
        frames = read_ani(data) if src.endswith(".ani") else [(read_cur(data), 0)]
        for n, (img, _) in enumerate(frames):
            path = svg_file(names[0], n, len(frames))
            if path.exists() and not (traced and EMPTY_LAYER in path.read_text(encoding="utf-8")):
                continue
            path.write_text(template(img, f"{names[0]} ({src})", vectorize(img) if traced else ""), encoding="utf-8")
            made += 1
    print(f"{made} {'traced' if traced else 'templates'} -> {SVG_DIR}")


def main() -> None:
    if "--templates" in sys.argv or "--vectorize" in sys.argv:
        templates("--vectorize" in sys.argv)
        return
    cursors = DST / "cursors"
    cursors.mkdir(parents=True, exist_ok=True)
    shapes = {}
    vector = 0
    for src, names in NAMES.items():
        data = (SRC / src).read_bytes()
        frames = read_ani(data) if src.endswith(".ani") else [(read_cur(data), 0)]
        paths = [svg_file(names[0], n, len(frames)) for n in range(len(frames))]
        # An untouched template has an empty Cursor layer: it would draw nothing
        svgs = [clean_svg(p) for p in paths] if all(p.exists() for p in paths) else None
        if svgs and any(b"<path" not in s and b"<rect" not in s and b"<circle" not in s and b"<ellipse" not in s and b"<polygon" not in s for s in svgs):
            svgs = None
        vector += bool(svgs)
        shapes[names[0]] = (frames, names[1:], svgs)
        (cursors / names[0]).write_bytes(xcursor(frames, svgs))
        for alias in names[1:]:
            link = cursors / alias
            link.unlink(missing_ok=True)
            link.symlink_to(names[0])
    hyprcursor(shapes)
    (DST / "index.theme").write_text("[Icon Theme]\nName=HollowKnight\nComment=Hollow Knight cursors by Newty (public domain)\nInherits=OutLier-v2,Adwaita\n")
    print(f"{len(NAMES)} cursors ({vector} vector) -> {DST}")


if __name__ == "__main__":
    main()
