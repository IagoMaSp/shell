pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Clipboard history backed by cliphist, plus pinned texts
Singleton {
    id: root

    readonly property string thumbDir: `${Paths.cache}/clipboard`
    property var entries: []
    property var pins: []
    property bool loading
    property int thumbVersion

    function refresh(): void {
        loading = true;
        listProc.running = false;
        listProc.running = true;
    }

    function thumb(entry: var): string {
        return `file://${thumbDir}/${entry.id}.png`;
    }

    function copy(entry: var): void {
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", entry.id]);
    }

    function copyText(text: string): void {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    function remove(entry: var): void {
        entries = entries.filter(e => e.id !== entry.id);
        Quickshell.execDetached(["sh", "-c", "cliphist list | awk -F'\\t' -v id=\"$1\" '$1 == id' | cliphist delete", "sh", entry.id]);
    }

    function wipe(): void {
        entries = [];
        Quickshell.execDetached(["cliphist", "wipe"]);
    }

    function isPinned(text: string): bool {
        return pins.includes(text);
    }

    function togglePin(text: string): void {
        pins = isPinned(text) ? pins.filter(p => p !== text) : [text].concat(pins);
        pinFile.setText(JSON.stringify(pins));
    }

    Process {
        id: listProc

        command: ["sh", "-c", "cliphist list | head -n 60"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const id = line.slice(0, tab);
                    const preview = line.slice(tab + 1);
                    const image = /^\[\[ binary data .* (png|jpe?g|webp|bmp|gif) /.test(preview);
                    if (preview.startsWith("[[ binary data") && !image)
                        continue;
                    out.push({
                        id,
                        preview,
                        image
                    });
                }
                root.entries = out;
                root.loading = false;
                const ids = out.filter(e => e.image).map(e => e.id);
                if (ids.length) {
                    thumbProc.command = ["sh", "-c", "mkdir -p \"$0\"; for id; do [ -f \"$0/$id.png\" ] || cliphist decode \"$id\" > \"$0/$id.png\"; done", root.thumbDir, ...ids];
                    thumbProc.running = true;
                }
            }
        }
    }

    Process {
        id: thumbProc

        onExited: root.thumbVersion++
    }

    FileView {
        id: pinFile

        path: `${Paths.state}/clipboard-pins.json`
        printErrors: false
        onLoaded: {
            try {
                root.pins = JSON.parse(text());
            } catch (e) {}
        }
    }
}
