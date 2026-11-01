#!/usr/bin/env python3
"""Generates the Hollow Knight colour scheme for caelestia-cli.

Base: the void black of the Knight's body, charcoal surfaces and bone-white text (the mask).
Accents: Lifeblood blue, Infection orange and Greenpath green, with one flavour per accent plus
"vessel" where the accent is the white/grey of the Knight and the Pure Vessel.

Output: assets/schemes/hollowknight/<flavour>/dark.txt, which caelestia-cli reads once the folder is
linked into its schemes dir (see the README section in assets/schemes/hollowknight).

Edit the colours below and rerun: python3 scripts/gen-hollowknight-scheme.py
"""

from pathlib import Path

# Base
VOID = "0b0b0e"
BONE = "e9e6df"

# Accents
SHELL = "e6e4de"  # The Knight's mask / Pure Vessel
NAIL = "a9adb5"  # Pale steel grey
LIFEBLOOD = "6cc9ff"
INFECTION = "ff8a2a"
GREENPATH = "74c98a"
GRIMM = "ff5c6a"  # Crimson, used as error when the primary is already orange

FLAVOURS = {
    # flavour: (primary, tertiary, error, success)
    "vessel": (SHELL, LIFEBLOOD, INFECTION, GREENPATH),
    "lifeblood": (LIFEBLOOD, SHELL, INFECTION, GREENPATH),
    "infection": (INFECTION, LIFEBLOOD, GRIMM, GREENPATH),
    "greenpath": (GREENPATH, LIFEBLOOD, INFECTION, "a8e08a"),
}


def rgb(hex_):
    return [int(hex_[i : i + 2], 16) for i in (0, 2, 4)]


def hexc(c):
    return "".join(f"{max(0, min(255, round(v))):02x}" for v in c)


def mix(a, b, t):
    """Mixes colour a towards b by t (0 = a, 1 = b)."""
    ca, cb = rgb(a), rgb(b)
    return hexc([x + (y - x) * t for x, y in zip(ca, cb)])


def accent(name, c):
    """Material-like tonal roles for a light accent on a dark surface."""
    return {
        name: c,
        f"{name}Dim": mix(c, "000000", 0.1),
        f"on{name.capitalize()}": mix(c, "000000", 0.78),
        f"{name}Container": mix(c, VOID, 0.74),
        f"on{name.capitalize()}Container": mix(c, "ffffff", 0.55),
        f"{name}Fixed": mix(c, "ffffff", 0.35),
        f"{name}FixedDim": mix(c, "ffffff", 0.2),
        f"on{name.capitalize()}Fixed": mix(c, "000000", 0.78),
        f"on{name.capitalize()}FixedVariant": mix(c, "000000", 0.55),
    }


def scheme(primary, tertiary, error, success):
    s = {
        "background": VOID,
        "onBackground": BONE,
        "surface": VOID,
        "surfaceDim": VOID,
        "surfaceBright": "26262d",
        "surfaceContainerLowest": "060608",
        "surfaceContainerLow": "0e0e12",
        "surfaceContainer": "121216",
        "surfaceContainerHigh": "18181d",
        "surfaceContainerHighest": "1e1e24",
        "onSurface": BONE,
        "surfaceVariant": "1e1e24",
        "onSurfaceVariant": "a7a49d",
        "outline": "6e6c67",
        "outlineVariant": "38383f",
        "inverseSurface": BONE,
        "inverseOnSurface": "2a2a30",
        "shadow": "000000",
        "scrim": "000000",
        "surfaceTint": primary,
    }
    s |= accent("primary", primary)
    s["inversePrimary"] = mix(primary, "000000", 0.45)
    s |= accent("secondary", NAIL)
    s |= accent("tertiary", tertiary)

    s |= {
        "error": error,
        "errorDim": mix(error, "000000", 0.1),
        "onError": mix(error, "000000", 0.78),
        "errorContainer": mix(error, VOID, 0.7),
        "onErrorContainer": mix(error, "ffffff", 0.55),
        "success": success,
        "onSuccess": mix(success, "000000", 0.78),
        "successContainer": mix(success, VOID, 0.72),
        "onSuccessContainer": mix(success, "ffffff", 0.55),
    }

    for role, c in (("primary", primary), ("secondary", NAIL), ("tertiary", tertiary)):
        key = mix(c, "000000", 0.35)
        s[f"{role}PaletteKeyColor"] = key
        s[f"{role}_paletteKeyColor"] = key
    s["neutralPaletteKeyColor"] = s["neutral_paletteKeyColor"] = "5c5b60"
    s["neutralVariantPaletteKeyColor"] = s["neutral_variant_paletteKeyColor"] = "605e5a"
    s["errorPaletteKeyColor"] = mix(error, "000000", 0.35)

    # Terminal: void black, infection reds/oranges, greenpath, lifeblood, dream nail pinks
    s |= {
        "term0": "1e1e24",
        "term1": "ff6a4d",
        "term2": GREENPATH,
        "term3": "ffb054",
        "term4": "7aa7ff",
        "term5": "d77bd0",
        "term6": LIFEBLOOD,
        "term7": "d8d5ce",
        "term8": "4b4b55",
        "term9": "ff8c73",
        "term10": "9bdcab",
        "term11": "ffc77f",
        "term12": "9cc1ff",
        "term13": "e7a2e2",
        "term14": "9adcff",
        "term15": "f2efe8",
    }

    # Catppuccin-style names used by some templates
    s |= {
        "rosewater": "f2e6dc",
        "flamingo": "eacbc0",
        "pink": "e7a2e2",
        "mauve": "c79ae8",
        "red": "ff6a4d",
        "maroon": "e38a7d",
        "peach": INFECTION,
        "yellow": "ffc77f",
        "green": GREENPATH,
        "teal": "6fd1c0",
        "sky": "8fd8ff",
        "sapphire": LIFEBLOOD,
        "blue": "7aa7ff",
        "lavender": "b3b8ff",
        "text": BONE,
        "subtext1": "c4c1ba",
        "subtext0": "a7a49d",
        "overlay2": "8a8882",
        "overlay1": "6e6c67",
        "overlay0": "57565a",
        "surface2": "3a3a41",
        "surface1": "2c2c33",
        "surface0": "1e1e24",
        "base": VOID,
        "mantle": "08080a",
        "crust": "050506",
    }

    # KDE colours
    s |= {
        "klink": tertiary,
        "klinkSelection": tertiary,
        "kvisited": "c79ae8",
        "kvisitedSelection": "c79ae8",
        "knegative": error,
        "knegativeSelection": error,
        "kneutral": "ffc77f",
        "kneutralSelection": "ffc77f",
        "kpositive": success,
        "kpositiveSelection": success,
    }
    return s


def main():
    out = Path(__file__).resolve().parent.parent / "assets" / "schemes" / "hollowknight"
    for flavour, colours in FLAVOURS.items():
        path = out / flavour / "dark.txt"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("".join(f"{k} {v}\n" for k, v in scheme(*colours).items()))
        print(path)


if __name__ == "__main__":
    main()
