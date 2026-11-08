import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// ">tr text": translate-shell to Spanish, or to English when the text already is Spanish
Item {
    id: root

    required property var list
    readonly property string query: list.translateQuery.trim()
    property string result
    property string target
    property bool missing

    function onClicked(): void {
        if (!result)
            return;
        Quickshell.execDetached(["wl-copy", result]);
        root.list.screenState.launcher = false;
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    onQueryChanged: {
        result = "";
        debounce.restart();
    }

    Timer {
        id: debounce

        interval: 400
        onTriggered: {
            if (!root.query)
                return;
            proc.running = false;
            proc.command = ["trans", "-b", "-no-ansi", ":es+en", root.query];
            proc.running = true;
        }
    }

    Process {
        id: proc

        stdout: StdioCollector {
            onStreamFinished: {
                // One line per target (es, en); the Spanish one echoes text that already is Spanish
                const lines = text.trim().split("\n").map(l => l.trim()).filter(l => l);
                const same = s => s.toLowerCase() === root.query.toLowerCase();
                const es = lines[0] ?? "";
                const useEn = !es || same(es);
                root.result = (useEn ? lines[1] : es) ?? "";
                root.target = useEn ? "EN" : "ES";
            }
        }
        onExited: code => root.missing = code === 127
    }

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.onClicked()
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.medium + 16
        anchors.rightMargin: Tokens.padding.medium + 16
        spacing: Tokens.spacing.medium

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            text: "translate"
            color: Hallownest.lifeblood
            fontStyle: Tokens.font.icon.extraLarge
        }

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.missing ? Tr.tr("Install translate-shell to translate") : !root.query ? Tr.tr("Type text to translate") : root.result || Tr.tr("Translating...")
            color: root.result ? Hallownest.soul : Hallownest.subtext
            elide: Text.ElideRight
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            visible: !!root.result
            text: `→ ${root.target}`
            color: Hallownest.subtext
            font.family: Hallownest.mono
        }
    }
}
