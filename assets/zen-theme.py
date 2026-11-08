#!/usr/bin/env python3
"""Installs the Hallownest userChrome in every Zen profile and writes the flavour colours."""
import configparser
import shutil
import sys
from pathlib import Path

ACCENTS = {"vessel": "#f0f4f8", "lifeblood": "#6cc9ff", "infection": "#ff8a2a", "greenpath": "#74c98a"}
STEELS = {"vessel": "#9ba4b5", "lifeblood": "#8fb3cc", "infection": "#b8a08f", "greenpath": "#94b39c"}
PREF = 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'

flavour = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] in ACCENTS else "vessel"
src = Path(__file__).parent / "zen" / "userChrome.css"
zen = Path.home() / ".config" / "zen"
ini = configparser.ConfigParser()
ini.read(zen / "profiles.ini")

colours = f""":root {{
    --hk-accent: {ACCENTS[flavour]};
    --hk-steel: {STEELS[flavour]};
    --hk-void: #06070a;
    --hk-shell: #0e1015;
    --hk-card: #14161c;
    --hk-text: #e2e8f0;
    --hk-subtext: #8a93a3;
}}
"""

for section in ini.sections():
    if not section.startswith("Profile") or "Path" not in ini[section]:
        continue
    path = ini[section]["Path"]
    profile = zen / path if ini[section].get("IsRelative", "1") == "1" else Path(path)
    if not profile.is_dir():
        continue
    chrome = profile / "chrome"
    chrome.mkdir(exist_ok=True)
    shutil.copyfile(src, chrome / "userChrome.css")
    (chrome / "hallownest-colors.css").write_text(colours)
    user_js = profile / "user.js"
    text = user_js.read_text() if user_js.exists() else ""
    if PREF not in text:
        user_js.write_text(text + ("\n" if text and not text.endswith("\n") else "") + PREF + "\n")
