pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.I18n
import qs.utils

// Saves screenshots, copies them to the clipboard and drops them on the Shelf
Singleton {
    id: root

    readonly property string dir: `${Paths.pictures}/Screenshots`

    function newPath(): string {
        return `${dir}/Screenshot_${Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss")}.png`;
    }

    function store(tmpPath: string): void {
        const dest = newPath();
        run(["sh", "-c", "mkdir -p \"$(dirname \"$2\")\" && mv \"$1\" \"$2\" && wl-copy --type image/png < \"$2\"", "sh", tmpPath, dest], dest);
    }

    function fullscreen(): void {
        const dest = newPath();
        run(["sh", "-c", "mkdir -p \"$(dirname \"$2\")\" && grim -o \"$1\" \"$2\" && wl-copy --type image/png < \"$2\"", "sh", Hypr.focusedMonitor?.name ?? "", dest], dest);
    }

    function run(command: var, dest: string): void {
        const proc = procComp.createObject(root, {
            command,
            dest
        });
        proc.running = true;
    }

    Component {
        id: procComp

        Process {
            id: proc

            property string dest

            onExited: code => {
                if (code === 0) {
                    Shelf.addUrls([`file://${proc.dest}`]);
                    Toaster.toast(Tr.tr("Screenshot taken"), Tr.tr("Copied and added to the Shelf"), "screenshot_region");
                } else {
                    Toaster.toast(Tr.tr("Screenshot failed"), proc.dest, "error", Toast.Error);
                }
                proc.destroy();
            }
        }
    }
}
