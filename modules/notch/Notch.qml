pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Scope {
    id: root

    function find(id: string): int {
        return NotchPages.pages.findIndex(p => p.id === id);
    }

    Variants {
        model: Screens.screens

        NotchWindow {
            required property ShellScreen modelData

            screen: modelData
        }
    }

    IpcHandler {
        function toggle(): void {
            const s = ShellState.forActive();
            s.notch = !s.notch;
        }

        function open(page: string): void {
            const s = ShellState.forActive();
            const idx = root.find(page);
            if (idx >= 0)
                s.notchPage = idx;
            s.notch = true;
        }

        function close(): void {
            ShellState.forActive().notch = false;
        }

        function mascot(): void {
            ShellState.forActive().mascotCalls++;
        }

        function react(name: string): void {
            Mascot.ready = true;
            Mascot.react(name);
        }

        function pages(): string {
            return NotchPages.pages.map(p => p.id).join("\n");
        }

        target: "notch"
    }
}
