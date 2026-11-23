#!/usr/bin/env python3
"""Checklist of the app icons to draw for the Hallownest icon theme.

Scans the installed desktop entries (skipping games and entries hidden everywhere) and writes
assets/icons/Hallownest/PENDIENTES.md with the file name each icon must have, marking the ones
already drawn in assets/icons/Hallownest/apps/scalable/.

Usage: python3 scripts/hallownest-icons.py
"""

import configparser
import os
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
THEME = REPO / "assets/icons/Hallownest"
DRAWN = THEME / "apps/scalable"


def app_dirs() -> list[Path]:
    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    dirs = [data_home, *map(Path, data_dirs), Path("/var/lib/flatpak/exports/share"), data_home / "flatpak/exports/share"]
    return [d / "applications" for d in dirs]


def entries() -> dict[str, dict]:
    found = {}
    # Earlier dirs win, like the desktop entry spec
    for d in app_dirs():
        if not d.is_dir():
            continue
        for f in sorted(d.rglob("*.desktop")):
            app_id = f.relative_to(d).as_posix().removesuffix(".desktop").replace("/", "-")
            if app_id in found:
                continue
            parser = configparser.RawConfigParser(strict=False, interpolation=None)
            parser.optionxform = str
            try:
                parser.read(f, encoding="utf-8")
                e = parser["Desktop Entry"]
            except (configparser.Error, KeyError, UnicodeDecodeError):
                continue
            found[app_id] = {
                "name": e.get("Name", app_id),
                "icon": e.get("Icon", "").strip(),
                "categories": e.get("Categories", ""),
                "hidden": e.get("NoDisplay", "false").lower() == "true" or e.get("Hidden", "false").lower() == "true",
                "type": e.get("Type", "Application"),
            }
    return found


def main() -> None:
    apps = [
        (a["name"], a["icon"])
        for a in entries().values()
        if a["type"] == "Application" and not a["hidden"] and a["icon"] and "Game" not in a["categories"].split(";")
    ]
    # Several entries can share one icon; one drawing covers them all
    by_icon: dict[str, list[str]] = {}
    for name, icon in apps:
        by_icon.setdefault(icon, []).append(name)

    rows = []
    for icon, names in sorted(by_icon.items(), key=lambda kv: kv[1][0].lower()):
        # Entries pointing at a file path can't be themed by name
        if "/" in icon:
            rows.append(("-", ", ".join(sorted(names)), f"no se puede (usa una ruta: `{icon}`)"))
            continue
        done = (DRAWN / f"{icon}.svg").exists()
        rows.append(("x" if done else " ", ", ".join(sorted(names)), f"`{icon}.svg`"))

    total = sum(1 for r in rows if r[0] != "-")
    drawn = sum(1 for r in rows if r[0] == "x")
    lines = [
        "# Iconos de apps pendientes",
        "",
        f"Generado por `scripts/hallownest-icons.py`. Hechos: **{drawn}/{total}**. Juegos excluidos.",
        "",
        "Guarda cada icono en `assets/icons/Hallownest/apps/scalable/` con el nombre de la tercera columna.",
        "",
        "| Hecho | App | Archivo |",
        "|---|---|---|",
        *[f"| {'✅' if d == 'x' else '⬜' if d == ' ' else '—'} | {n} | {f} |" for d, n, f in rows],
        "",
    ]
    (THEME / "PENDIENTES.md").write_text("\n".join(lines), encoding="utf-8")
    print(f"{drawn}/{total} iconos hechos -> {THEME / 'PENDIENTES.md'}")


if __name__ == "__main__":
    main()
