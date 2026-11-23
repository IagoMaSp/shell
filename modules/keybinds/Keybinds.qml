pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.components.containers
import qs.components.misc
import qs.services

// Cheatsheet of the Hyprland keybinds, toggled with the paleshell:keybinds global shortcut.
// Only binds with a description ("Section|Text") are listed, see hypr/hyprland/keybinds.lua.
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
            name: "keybinds"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: closing ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            KeybindsContent {
                id: content

                property bool shown

                anchors.fill: parent
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

        target: "keybinds"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "keybinds"
        description: "Show the keybinds cheatsheet"
        onPressed: root.toggle()
    }
}
