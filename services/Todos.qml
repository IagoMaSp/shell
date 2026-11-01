pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var items: []
    property var alert: null

    readonly property int doneToday: items.filter(i => i.done && isToday(i.doneAt)).length
    readonly property int totalToday: items.filter(i => !i.done).length + doneToday

    function isToday(ms: real): bool {
        if (!ms)
            return false;
        const d = new Date(ms);
        const now = new Date();
        return d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth() && d.getDate() === now.getDate();
    }

    function parseDue(text: string): real {
        const m = /^\s*(\d{1,2})[:.](\d{2})\s*$/.exec(text ?? "");
        if (!m)
            return 0;
        const h = parseInt(m[1]);
        const min = parseInt(m[2]);
        if (h > 23 || min > 59)
            return 0;
        const d = new Date();
        d.setHours(h, min, 0, 0);
        if (d.getTime() < Date.now() - 60000)
            d.setDate(d.getDate() + 1);
        return d.getTime();
    }

    function dueStr(item: var): string {
        return item?.dueAt ? Qt.locale().toString(new Date(item.dueAt), "HH:mm") : "";
    }

    function add(title: string, colour: int, due: string): void {
        const trimmed = title.trim();
        if (!trimmed)
            return;
        items = items.concat([
            {
                id: `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`,
                title: trimmed,
                colour,
                dueAt: parseDue(due),
                done: false,
                doneAt: 0,
                snoozedUntil: 0,
                alerted: false,
                created: Date.now()
            }
        ]);
        changed();
    }

    function update(id: string, patch: var): void {
        items = items.map(i => i.id === id ? Object.assign({}, i, patch) : i);
        changed();
    }

    function edit(id: string, title: string, colour: int, due: string): void {
        const dueAt = parseDue(due);
        const old = items.find(i => i.id === id);
        const patch = {
            title: title.trim() || old?.title,
            colour,
            dueAt
        };
        if (dueAt !== old?.dueAt) {
            patch.alerted = false;
            patch.snoozedUntil = 0;
        }
        update(id, patch);
    }

    function toggle(id: string): void {
        const item = items.find(i => i.id === id);
        if (!item)
            return;
        update(id, {
            done: !item.done,
            doneAt: item.done ? 0 : Date.now()
        });
        if (alert?.id === id)
            alert = null;
    }

    function remove(id: string): void {
        items = items.filter(i => i.id !== id);
        if (alert?.id === id)
            alert = null;
        changed();
    }

    function clearDone(): void {
        items = items.filter(i => !i.done);
        changed();
    }

    function snooze(id: string): void {
        update(id, {
            snoozedUntil: Date.now() + NotchSettings.snoozeMinutes * 60000,
            alerted: false
        });
        alert = null;
        Mascot.react("angry");
    }

    function dismissAlert(): void {
        alert = null;
    }

    function changed(): void {
        schedule();
        file.setText(JSON.stringify(items, null, 2));
    }

    function triggerTime(item: var): real {
        if (item.done || item.alerted)
            return 0;
        return item.snoozedUntil || item.dueAt || 0;
    }

    function schedule(): void {
        const times = items.map(i => triggerTime(i)).filter(t => t > 0);
        if (!times.length) {
            dueTimer.stop();
            return;
        }
        dueTimer.interval = Math.min(2147483647, Math.max(0, Math.min(...times) - Date.now()));
        dueTimer.restart();
    }

    function fire(): void {
        const now = Date.now() + 500;
        const due = items.find(i => {
            const t = triggerTime(i);
            return t > 0 && t <= now;
        });
        if (due) {
            alert = due;
            Quickshell.execDetached(["pw-play", "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"]);
            update(due.id, {
                alerted: true
            });
        } else {
            schedule();
        }
    }

    Timer {
        id: dueTimer

        onTriggered: root.fire()
    }

    FileView {
        id: file

        path: `${NotchSettings.dir}/todos.json`
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.items = (Array.isArray(data) ? data : []).filter(i => !i.done || root.isToday(i.doneAt));
            } catch (e) {
                root.items = [];
            }
            root.schedule();
        }
    }
}
