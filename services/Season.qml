pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Seasonal decorations: Grimm Troupe in October, snow in December
Singleton {
    id: root

    // "" = follow the calendar; "none" disables it (set from IPC, not persisted)
    property string override
    readonly property string calendar: clock.date.getMonth() === 9 ? "grimm" : clock.date.getMonth() === 11 ? "winter" : ""
    readonly property string current: override === "none" || !NotchSettings.values.animSeasons ? "" : override || calendar

    SystemClock {
        id: clock

        precision: SystemClock.Hours
    }

    IpcHandler {
        function set(name: string): void {
            root.override = name === "auto" ? "" : name;
        }

        function get(): string {
            return root.current || "none";
        }

        target: "season"
    }
}
