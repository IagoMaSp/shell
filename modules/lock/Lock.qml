pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.components.containers
import qs.components.misc

Scope {
    id: root

    property alias lock: lock
    // Set by IdleMonitors a few seconds before the idle lock; any activity clears it
    property bool resting
    property real restProgress

    onRestingChanged: {
        restAnim.stop();
        restAnim.to = resting ? 1 : 0;
        restAnim.duration = resting ? 8000 : 300;
        restAnim.start();
    }

    WlSessionLock {
        id: lock

        signal unlock

        onLockedChanged: {
            if (locked)
                root.resting = false;
        }

        LockSurface {
            lock: lock
            pam: pam
        }
    }

    NumberAnimation {
        id: restAnim

        target: root
        property: "restProgress"
        easing.type: Easing.InOutSine
    }

    Variants {
        model: root.restProgress > 0 ? Quickshell.screens : []

        StyledWindow {
            required property ShellScreen modelData

            screen: modelData
            name: "bench-rest"
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            mask: Region {}

            BenchRest {
                anchors.fill: parent
                progress: root.restProgress
            }

            Bench {
                canvasScale: parent.height * 0.135 / 180
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height - 8 - 200 * canvasScale
                opacity: root.restProgress
            }
        }
    }

    Pam {
        id: pam

        lock: lock
    }

    Loader {
        asynchronous: true
        active: true
        onLoaded: active = false

        // Force a load of a screencopy so the one in the lock works
        // My guess is the ICC backend loads async on first request, which if the lock is
        // the first request it fails to capture (because it's async and the compositor
        // refuses capture when locked)
        sourceComponent: ScreencopyView {
            captureSource: Quickshell.screens[0]
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "lock"
        description: "Lock the current session"
        onPressed: lock.locked = true
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "unlock"
        description: "Unlock the current session"
        onPressed: lock.unlock()
    }

    IpcHandler {
        function lock(): void {
            lock.locked = true;
        }

        function unlock(): void {
            lock.unlock();
        }

        function isLocked(): bool {
            return lock.locked;
        }

        target: "lock"
    }
}
