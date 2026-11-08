pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.components.containers
import qs.components.misc
import qs.services

// Workspace overview, toggled with the paleshell:overview global shortcut.
Scope {
    id: root

    function toggle(): void {
        if (loader.active)
            loader.item.close();
        else
            loader.activeAsync = true;
    }

    LazyLoader {
        id: loader

        StyledWindow {
            id: win

            property bool closing

            function close(): void {
                closing = true;
            }

            screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]
            name: "overview"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: closing ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            OverviewContent {
                id: content

                property bool shown

                anchors.fill: parent
                monitor: Hypr.monitorFor(win.screen)
                opacity: win.closing ? 0 : shown ? 1 : 0
                onClose: win.close()

                Component.onCompleted: shown = true

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                        onRunningChanged: {
                            if (!running && win.closing)
                                loader.active = false;
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        function toggle(): void {
            root.toggle();
        }

        target: "overview"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "overview"
        description: "Toggle the workspace overview"
        onPressed: root.toggle()
    }
}
