#!/usr/bin/env bash
# Builds PaleShell's C++ plugin, links the repo where Quickshell looks for configs and seeds the
# default settings. Nothing is installed system-wide; the steps that need root are printed at the end.
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)
config=${XDG_CONFIG_HOME:-$HOME/.config}
dest=$config/quickshell/paleshell

missing=()
for cmd in qs cmake ninja git python3 caelestia hyprctl; do
    command -v "$cmd" >/dev/null || missing+=("$cmd")
done
if ((${#missing[@]})); then
    echo "Missing commands: ${missing[*]} (see the dependencies in README.md)" >&2
    exit 1
fi

if [ "$(realpath -m "$dest")" != "$repo" ]; then
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo "$dest already exists and is not this repo; move it away first" >&2
        exit 1
    fi
    mkdir -p "$(dirname "$dest")"
    ln -s "$repo" "$dest"
    echo "Linked $dest -> $repo"
fi

if [ ! -f "$repo/build/CMakeCache.txt" ]; then
    version=$(git -C "$repo" describe --tags --abbrev=0 2>/dev/null || echo 0.0.0)
    cmake -S "$repo" -B "$repo/build" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DINSTALL_QMLDIR=lib/qt6/qml -DVERSION="$version"
fi
cmake --build "$repo/build"

mkdir -p "$config/paleshell"
if [ ! -f "$config/paleshell/shell.json" ]; then
    cp "$repo/extras/shell.json" "$config/paleshell/shell.json"
    echo "Wrote default settings to $config/paleshell/shell.json"
fi

schemes=$(python3 -c 'import caelestia, os; print(os.path.dirname(caelestia.__file__))')/data/schemes
cat <<EOF

Done. Remaining steps:

1. Register the Hollow Knight colour scheme with caelestia-cli (needs root):

   sudo ln -sfn "$repo/assets/schemes/hollowknight" "$schemes/hollowknight"

2. Add these lines at the end of ~/.config/hypr/hyprland.lua and remove any other bar/shell
   autostart (e.g. "caelestia shell" or "qs -c caelestia"):

   package.path = package.path .. ";" .. os.getenv("HOME") .. "/.config/quickshell/paleshell/extras/hyprland/?.lua"
   require("paleshell")

3. Log out and back in (or run: hyprctl reload, then qs -c paleshell -n -d).
EOF
