pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Tracks whether some app is using the microphone or the camera
Singleton {
    id: root

    readonly property var micStreams: Pipewire.nodes.values.filter(n => n.isStream && n.type === PwNodeType.AudioInStream)
    readonly property var micApps: {
        const apps = [];
        for (const n of micStreams) {
            const props = n.properties ?? {};
            // Streams recording the speakers' monitor (visualisers, beat detection) are not the mic
            if (String(props["stream.capture.sink"]) === "true")
                continue;
            const app = props["application.name"] || props["application.process.binary"] || n.name;
            if (/cava|quickshell|paleshell|caelestia/i.test(`${app} ${n.name}`))
                continue;
            if (!apps.includes(app))
                apps.push(app);
        }
        return apps;
    }
    readonly property bool micInUse: micApps.length > 0
    property bool cameraInUse

    PwObjectTracker {
        objects: root.micStreams
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!cameraProc.running)
                cameraProc.running = true;
        }
    }

    Process {
        id: cameraProc

        command: ["sh", "-c", "ls /dev/video* >/dev/null 2>&1 && fuser -s /dev/video*"]
        onExited: code => root.cameraInUse = code === 0
    }
}
