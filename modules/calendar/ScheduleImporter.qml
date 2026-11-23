pragma Singleton

import Quickshell
import Quickshell.Io
import Caelestia.I18n
import qs.components.filedialog
import qs.services

// File picker for importing .ics schedules. Uses the system (GTK) file chooser through zenity, falling
// back to the shell's own dialog if zenity isn't installed. Lives outside the dashboard so the picker
// survives the dashboard closing while a file is being picked.
Singleton {
    function open(): void {
        if (!picker.running)
            picker.running = true;
    }

    Process {
        id: picker

        command: ["sh", "-c", "command -v zenity >/dev/null || exit 127; exec zenity --file-selection --title=\"$1\" --file-filter=\"$2 | *.ics *.ICS\"", "sh", Tr.tr("Import schedule"), Tr.tr("Calendar files")]
        stdout: StdioCollector {
            id: pickerOut
        }
        onExited: code => {
            if (code === 0 && pickerOut.text.trim())
                Events.importFile(pickerOut.text.trim());
            else if (code === 127)
                dialog.open();
        }
    }

    FileDialog {
        id: dialog

        title: Tr.tr("Import schedule")
        filterLabel: Tr.tr("Calendar files")
        filters: ["ics"]
        onAccepted: path => Events.importFile(path)
    }
}
