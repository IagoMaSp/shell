pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property color void_: "#06070a"
    readonly property color shell: "#0e1015"
    readonly property color card: "#14161c"
    readonly property color button: "#18181c"
    readonly property color steel: "#9ba4b5"
    readonly property color border: Qt.alpha(steel, 0.15)
    readonly property color soul: "#f0f4f8"
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

    readonly property string serif: cinzel.status === FontLoader.Ready ? cinzel.name : "serif"
    readonly property string mono: "JetBrainsMono Nerd Font"

    FontLoader {
        id: cinzel

        source: Quickshell.shellPath("assets/fonts/cinzel/Cinzel.ttf")
    }
}
