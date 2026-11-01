pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    property var pending: null
    property bool ready
    property real lastVibe
    property real lowLevel: 1

    readonly property bool allDone: Todos.totalToday > 0 && Todos.doneToday === Todos.totalToday
    readonly property real battery: UPower.displayDevice.percentage
    readonly property string track: NotchMedia.player?.trackTitle ?? ""

    function react(name: string): void {
        if (!ready || !NotchSettings.mascot || !NotchSettings.values.mascotReactions)
            return;
        pending = {
            name,
            at: Date.now()
        };
    }

    function take(): string {
        const p = pending;
        pending = null;
        return p && Date.now() - p.at < 60000 ? p.name : "";
    }

    onAllDoneChanged: {
        if (allDone)
            react("happy");
    }

    onBatteryChanged: {
        if (!UPower.onBattery || !UPower.displayDevice.ready)
            return;
        if (battery <= 0.05 && lowLevel > 0.05) {
            lowLevel = 0.05;
            react("infected");
        } else if (battery <= 0.15 && lowLevel > 0.15) {
            lowLevel = 0.15;
            react("cry");
        }
    }

    onTrackChanged: {
        if (!track || !(NotchMedia.player?.isPlaying ?? false) || Date.now() - lastVibe < 180000)
            return;
        lastVibe = Date.now();
        react("vibe");
    }

    Timer {
        running: true
        interval: 5000
        onTriggered: root.ready = true
    }

    Connections {
        function onOnBatteryChanged(): void {
            if (!UPower.onBattery)
                root.lowLevel = 1;
        }

        target: UPower
    }

    Connections {
        function onCurrentChanged(): void {
            const c = NotchOsd.current;
            if (!c)
                return;
            const reactions = {
                battery_charging_full: "soul",
                power_off: "sad",
                wifi: "happy",
                wifi_off: "shocked",
                bluetooth_connected: "happy",
                headphones: "vibe",
                coffee: "soul",
                psychology: "angry"
            };
            if (reactions[c.icon])
                root.react(reactions[c.icon]);
        }

        target: NotchOsd
    }
}
