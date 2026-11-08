#!/usr/bin/env python3
"""Installs the Hallownest CSS snippet in every Obsidian vault and enables it with dark mode."""
import base64
import json
import sys
from pathlib import Path

ACCENTS = {"vessel": "#f0f4f8", "lifeblood": "#6cc9ff", "infection": "#ff8a2a", "greenpath": "#74c98a"}
STEELS = {"vessel": "#9ba4b5", "lifeblood": "#8fb3cc", "infection": "#b8a08f", "greenpath": "#94b39c"}
CHARMS = {"grimm": "#e63946", "gold": "#f4a261", "unn": "#52b788", "lifeblood": "#38bdf8"}


def rgb(hex_colour):
    return ", ".join(str(int(hex_colour[i:i + 2], 16)) for i in (1, 3, 5))


flavour = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] in ACCENTS else "vessel"
assets = Path(__file__).parent
config = Path.home() / ".config" / "obsidian" / "obsidian.json"
if not config.exists():
    sys.exit(0)

font = base64.b64encode((assets / "fonts" / "cinzel" / "Cinzel.ttf").read_bytes()).decode()
charms = "".join(f"    --hk-{n}: {c};\n    --hk-{n}-rgb: {rgb(c)};\n" for n, c in CHARMS.items())
css = f"""@font-face {{
    font-family: "Cinzel";
    src: url(data:font/ttf;base64,{font}) format("truetype");
    font-weight: 400 900;
}}

.theme-dark {{
    --hk-accent: {ACCENTS[flavour]};
    --hk-steel: {STEELS[flavour]};
    --hk-border: {STEELS[flavour]}26;
    --hk-void: #06070a;
    --hk-shell: #0e1015;
    --hk-card: #14161c;
    --hk-text: #e2e8f0;
    --hk-subtext: #8a93a3;
    --hk-faint: #4a505c;
{charms}}}

""" + (assets / "obsidian" / "hallownest.css").read_text()

for vault in json.loads(config.read_text()).get("vaults", {}).values():
    dot = Path(vault["path"]) / ".obsidian"
    if not dot.is_dir():
        continue
    (dot / "snippets").mkdir(exist_ok=True)
    (dot / "snippets" / "hallownest.css").write_text(css)

    appearance_file = dot / "appearance.json"
    appearance = json.loads(appearance_file.read_text() or "{}") if appearance_file.exists() else {}
    snippets = appearance.setdefault("enabledCssSnippets", [])
    if "hallownest" not in snippets or appearance.get("theme") != "obsidian":
        if "hallownest" not in snippets:
            snippets.append("hallownest")
        appearance["theme"] = "obsidian"
        appearance_file.write_text(json.dumps(appearance, indent=2))
