pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n

Singleton {
    id: root

    property string mode: "focus"
    property bool running
    property real endsAt
    property int remaining: duration
    property int completedToday
    property string day: today()

    readonly property int duration: (mode === "focus" ? NotchSettings.pomodoroFocus : NotchSettings.pomodoroBreak) * 60
    readonly property real progress: duration > 0 ? 1 - remaining / duration : 0
    readonly property string remainingStr: `${Math.floor(remaining / 60)}:${(remaining % 60).toString().padStart(2, "0")}`
    readonly property bool active: running || remaining !== duration

    function today(): string {
        return Qt.formatDate(new Date(), "yyyy-MM-dd");
    }

    function start(): void {
        if (remaining <= 0)
            remaining = duration;
        endsAt = Date.now() + remaining * 1000;
        running = true;
        save();
    }

    function pause(): void {
        tick();
        running = false;
        save();
    }

    function toggle(): void {
        if (running)
            pause();
        else
            start();
    }

    function reset(): void {
        running = false;
        remaining = duration;
        save();
    }

    function setMode(newMode: string): void {
        running = false;
        mode = newMode;
        remaining = duration;
        save();
    }

    function skip(): void {
        setMode(mode === "focus" ? "break" : "focus");
    }

    function tick(): void {
        if (!running)
            return;
        remaining = Math.max(0, Math.ceil((endsAt - Date.now()) / 1000));
        if (remaining <= 0)
            finish();
    }

    function finish(): void {
        const wasFocus = mode === "focus";
        if (day !== today()) {
            day = today();
            completedToday = 0;
        }
        if (wasFocus)
            completedToday++;
        Quickshell.execDetached(["pw-play", "/usr/share/sounds/freedesktop/stereo/complete.oga"]);
        NotchOsd.show("pomodoro", wasFocus ? "coffee" : "psychology", wasFocus ? Tr.tr("Focus done · take a break") : Tr.tr("Break over · back to focus"), -1);
        setMode(wasFocus ? "break" : "focus");
    }

    function save(): void {
        file.setText(JSON.stringify({
            mode,
            running,
            endsAt,
            remaining,
            completedToday,
            day
        }));
    }

    onDurationChanged: {
        if (!running)
            remaining = duration;
    }

    Timer {
        running: root.running
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }

    FileView {
        id: file

        path: `${NotchSettings.dir}/pomodoro.json`
        printErrors: false

        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.mode = d.mode === "break" ? "break" : "focus";
                root.endsAt = d.endsAt ?? 0;
                root.remaining = d.remaining ?? root.duration;
                root.day = d.day ?? root.today();
                root.completedToday = root.day === root.today() ? (d.completedToday ?? 0) : 0;
                root.running = !!d.running;
                root.tick();
            } catch (e) {}
        }
    }
}
