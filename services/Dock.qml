pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils

Singleton {
    id: root

    // false = island at the top, true = dock at the bottom
    property bool mode
    // Desktop entry ids, in dock order
    property var pinned: ["zen", "foot", "thunar"]
    // Pinned apps first, then running ones; windows grouped by desktop entry (or class)
    readonly property var entries: {
        const groups = {};
        const order = [];
        for (const id of pinned) {
            const entry = DesktopEntries.byId(id);
            if (!entry)
                continue;
            groups[id] = {
                id,
                entry,
                pinned: true,
                windows: []
            };
            order.push(id);
        }
        for (const t of Hypr.toplevels.values) {
            const cls = t.lastIpcObject?.class;
            if (!cls)
                continue;
            const entry = DesktopEntries.heuristicLookup(cls);
            const key = entry?.id ?? cls;
            if (!groups[key]) {
                groups[key] = {
                    id: key,
                    entry,
                    pinned: false,
                    windows: []
                };
                order.push(key);
            }
            groups[key].windows.push(t);
        }
        return order.map(k => groups[k]);
    }

    function isPinned(id: string): bool {
        return pinned.includes(id);
    }

    // Inserts or moves id to index, counted in the list without id
    function pin(id: string, index: int): void {
        if (!id)
            return;
        const list = pinned.filter(p => p !== id);
        const at = Math.max(0, Math.min(index, list.length));
        list.splice(at, 0, id);
        pinned = list;
        saveTimer.restart();
    }

    function toggle(): void {
        mode = !mode;
        saveTimer.restart();
    }

    function unpin(id: string): void {
        pinned = pinned.filter(p => p !== id);
        saveTimer.restart();
    }

    function focus(t: var): void {
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "address:0x${t.address}" })` : `focuswindow address:0x${t.address}`);
    }

    function launch(entry: DesktopEntry): void {
        if (entry.runInTerminal)
            Quickshell.execDetached([...GlobalConfig.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...entry.command]);
        else
            entry.execute();
    }

    // The group of an app with open windows, or null
    function openGroup(id: string): var {
        return entries.find(e => e.id === id && e.windows.length > 0) ?? null;
    }

    // Launch if closed; otherwise focus it, cycling through its windows when already focused
    function activate(group: var): void {
        const windows = group.windows;
        if (windows.length === 0) {
            if (group.entry)
                launch(group.entry);
            return;
        }
        const idx = windows.indexOf(Hypr.activeToplevel);
        focus(windows[idx < 0 ? 0 : (idx + 1) % windows.length]);
    }

    Timer {
        id: saveTimer

        interval: 200
        onTriggered: file.setText(JSON.stringify({
                mode: root.mode,
                pinned: root.pinned
            }, null, 2))
    }

    FileView {
        id: file

        path: `${Paths.state}/dock.json`
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (Array.isArray(data.pinned))
                    root.pinned = data.pinned;
                root.mode = data.mode === true;
            } catch (e) {}
        }
    }
}
