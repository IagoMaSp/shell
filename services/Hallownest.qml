pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    readonly property color void_: "#06070a"
    readonly property color shell: "#0e1015"
    readonly property color card: "#14161c"
    readonly property color button: "#18181c"
    readonly property var steels: ({
            vessel: "#9ba4b5",
            lifeblood: "#8fb3cc",
            infection: "#b8a08f",
            greenpath: "#94b39c"
        })
    readonly property color steel: steels[flavour] ?? "#9ba4b5"
    readonly property color border: Qt.alpha(steel, 0.15)
    readonly property var accents: ({
            vessel: "#f0f4f8",
            lifeblood: "#6cc9ff",
            infection: "#ff8a2a",
            greenpath: "#74c98a"
        })
    readonly property color soul: accents[flavour] ?? "#f0f4f8"
    readonly property color text: "#e2e8f0"
    readonly property color subtext: "#8a93a3"
    readonly property color faint: "#4a505c"
    readonly property color lifeblood: "#38bdf8"
    readonly property color lifebloodDeep: "#00b4d8"
    readonly property color lifebloodSoft: "#48cae4"
    readonly property color glowBlue: "#4cc9f0"
    readonly property color hotSpring: "#2dd4bf"
    readonly property color infection: "#ff6b35"
    readonly property color grimm: "#e63946"
    readonly property color gold: "#f4a261"
    readonly property color unn: "#52b788"
    readonly property color crystal: "#a8dadc"
    readonly property var charms: [grimm, gold, unn, crystal]

    readonly property var flavours: ["vessel", "lifeblood", "infection", "greenpath"]
    property string flavour: "vessel"
    property bool loaded

    readonly property string serif: cinzel.status === FontLoader.Ready ? cinzel.name : "serif"
    readonly property string mono: "JetBrainsMono Nerd Font"

    function setFlavour(name: string): void {
        if (!flavours.includes(name) || name === flavour)
            return;
        flavour = name;
        state.setText(JSON.stringify({
            flavour
        }));
        // The icons are re-tinted before caelestia reapplies the icon theme; thunar-theme.py must
        // run after caelestia, which rewrites thunar.css
        Quickshell.execDetached(["sh", "-c", `python3 "$1" ${name}; caelestia scheme set -n hollowknight -f ${name} -m dark; python3 "$0" ${name}; command -v spicetify >/dev/null && spicetify -q refresh`, Quickshell.shellPath("assets/thunar-theme.py"), Quickshell.shellPath("assets/icon-theme.py")]);
        Quickshell.execDetached(["python3", Quickshell.shellPath("assets/zen-theme.py"), name]);
        Quickshell.execDetached(["python3", Quickshell.shellPath("assets/obsidian-theme.py"), name]);
        Quickshell.execDetached(["python3", Quickshell.shellPath("assets/apps-theme.py"), name]);
    }

    FileView {
        id: state

        path: `${Paths.state}/hallownest.json`
        printErrors: false

        onLoaded: {
            try {
                const f = JSON.parse(text()).flavour;
                if (root.flavours.includes(f))
                    root.flavour = f;
            } catch (e) {}
            root.loaded = true;
            Quickshell.execDetached(["python3", Quickshell.shellPath("assets/thunar-theme.py"), root.flavour]);
            Quickshell.execDetached(["python3", Quickshell.shellPath("assets/icon-theme.py"), root.flavour]);
        }
        onLoadFailed: root.loaded = true
    }

    IpcHandler {
        function flavour(name: string): void {
            root.setFlavour(name);
        }

        function list(): string {
            return root.flavours.join("\n");
        }

        target: "hallownest"
    }

    FontLoader {
        id: cinzel

        source: Quickshell.shellPath("assets/fonts/cinzel/Cinzel.ttf")
    }
}
