#!/usr/bin/env python3
# Prints the custom search engines of the default Zen Browser profile as JSON:
# [{"name": "YouTube", "aliases": ["@yt"], "url": "https://...{searchTerms}"}]

import configparser
import json
import sys
from pathlib import Path

ZEN_DIR = Path.home() / ".config/zen"


def lz4_block(src: bytes) -> bytes:
    dst = bytearray()
    i = 0
    while i < len(src):
        token = src[i]
        i += 1
        length = token >> 4
        if length == 15:
            while True:
                b = src[i]
                i += 1
                length += b
                if b != 255:
                    break
        dst += src[i : i + length]
        i += length
        if i >= len(src):
            break
        offset = src[i] | (src[i + 1] << 8)
        i += 2
        length = token & 15
        if length == 15:
            while True:
                b = src[i]
                i += 1
                length += b
                if b != 255:
                    break
        for _ in range(length + 4):
            dst.append(dst[-offset])
    return bytes(dst)


def default_profile() -> Path | None:
    ini = configparser.ConfigParser(interpolation=None)
    ini.read(ZEN_DIR / "profiles.ini")
    # The [Install*] section holds the profile the browser actually uses
    for section in ini.sections():
        if section.startswith("Install") and ini.has_option(section, "Default"):
            return ZEN_DIR / ini.get(section, "Default")
    for section in ini.sections():
        if ini.get(section, "Default", fallback="0") == "1" and ini.has_option(section, "Path"):
            path = ini.get(section, "Path")
            return ZEN_DIR / path if ini.get(section, "IsRelative", fallback="1") == "1" else Path(path)
    return None


def main() -> None:
    engines = []
    profile = default_profile()
    try:
        data = (profile / "search.json.mozlz4").read_bytes()
        assert data[:8] == b"mozLz40\0"
        for e in json.loads(lz4_block(data[12:]))["engines"]:
            if e.get("_metaData", {}).get("hidden"):
                continue
            url = next((u["template"] for u in e.get("_urls", []) if u.get("type", "text/html") == "text/html"), None)
            if url and "{searchTerms}" in url:
                aliases = list(e.get("_definedAliases") or [])
                if alias := e.get("_metaData", {}).get("alias"):
                    aliases.append(alias)
                engines.append({"name": e["_name"], "aliases": aliases, "url": url})
    except Exception as err:
        print(f"zen-engines: {err}", file=sys.stderr)
    print(json.dumps(engines))


if __name__ == "__main__":
    main()
