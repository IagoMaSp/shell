pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import qs.components.misc
import qs.services

Scope {
    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "dock"
        description: "Switch between the top island and the bottom dock"
        onPressed: Dock.toggle()
    }

    IpcHandler {
        function toggle(): void {
            Dock.toggle();
        }

        target: "dock"
    }

    Variants {
        model: Screens.screens

        Scope {
            id: screenScope

            required property ShellScreen modelData

            DockWindow {
                id: dock

                screen: screenScope.modelData
            }

            GooWindow {
                screen: screenScope.modelData
                progress: dock.progress
                running: dock.gooRunning
                dockWidth: dock.islandWidth
                dockHeight: dock.islandHeight
            }
        }
    }
}
