pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.hallownest
import qs.services
import qs.modules.notch

NotchPage {
    id: root

    function launched(): void {
        promptField.text = "";
        root.screenState.notch = false;
    }

    function relativeTime(ms: real): string {
        const mins = Math.floor((Date.now() - ms) / 60000);
        if (mins < 1)
            return Tr.tr("now");
        if (mins < 60)
            return Tr.tr("%1 min ago").arg(mins);
        const hours = Math.floor(mins / 60);
        if (hours < 24)
            return Tr.tr("%1 h ago").arg(hours);
        const days = Math.floor(hours / 24);
        if (days < 7)
            return Tr.tr("%1 d ago").arg(days);
        return Qt.locale().toString(new Date(ms), "d MMM");
    }

    implicitWidth: 760
    implicitHeight: layout.implicitHeight

    Component.onCompleted: AiAgents.reload()

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.small
            spacing: Tokens.spacing.medium

            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 36
                implicitHeight: 36

                IconImage {
                    id: providerIcon

                    anchors.fill: parent
                    source: Quickshell.iconPath(AiAgents.provider.icon, true)
                    visible: source.toString() !== ""
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: !providerIcon.visible
                    text: AiAgents.provider.fallbackIcon
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.2).build()
                    color: Hallownest.lifeblood
                }
            }

            Column {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true

                StyledText {
                    text: AiAgents.provider.name
                    font: Tokens.font.body.builders.large.size(20).weight(Font.DemiBold).build()
                    color: Hallownest.text
                }

                StyledText {
                    text: {
                        if (!AiAgents.hasCli)
                            return Tr.tr("Not installed");
                        const v = AiAgents.versions[AiAgents.providerId];
                        return v ? `v${v}` : "";
                    }
                    font: Tokens.font.body.small
                    color: AiAgents.hasCli ? Hallownest.subtext : Hallownest.grimm
                }
            }

            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: Tokens.spacing.extraSmall

                Repeater {
                    model: AiAgents.providers

                    delegate: Chip {
                        required property var modelData

                        text: modelData.name
                        selected: modelData.id === AiAgents.providerId
                        onClicked: AiAgents.setProvider(modelData.id)
                    }
                }
            }

            HkButton {
                implicitHeight: 28
                Layout.alignment: Qt.AlignVCenter
                icon: "refresh"
                disabled: AiAgents.loading
                onClicked: AiAgents.reload()
            }
        }

        AgentApproval {
            Layout.fillWidth: true
            visible: !!AgentSessions.current
            approval: AgentSessions.current
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledRect {
                Layout.preferredWidth: 390
                Layout.fillHeight: true
                implicitHeight: live.implicitHeight + Tokens.padding.large * 2

                radius: Tokens.rounding.extraLarge
                color: Hallownest.card
                border.width: 1
                border.color: Hallownest.border

                ColumnLayout {
                    id: live

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.small
                        Layout.bottomMargin: Tokens.spacing.extraSmall
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: Tr.tr("Live sessions")
                            color: Hallownest.steel
                            font.family: Hallownest.serif
                            font.pointSize: 11
                            font.weight: Font.Bold
                        }

                        StyledText {
                            visible: AgentSessions.sessions.length > 0
                            text: AgentSessions.sessions.length
                            color: Hallownest.subtext
                            font.family: Hallownest.serif
                            font.pointSize: 10
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.small
                        visible: !AgentSessions.hooksInstalled && AgentSessions.sessions.length === 0
                        spacing: Tokens.spacing.small

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Install the Claude Code hooks to follow your sessions live and answer their requests from here.")
                            wrapMode: Text.WordWrap
                            color: Hallownest.subtext
                            font.pointSize: 9
                        }

                        HkButton {
                            icon: "add_link"
                            text: Tr.tr("Install hooks")
                            accent: Hallownest.lifeblood
                            tinted: true
                            disabled: AgentSessions.hooksBusy
                            onClicked: AgentSessions.installHooks(true)
                        }
                    }

                    StyledText {
                        Layout.leftMargin: Tokens.padding.small
                        visible: AgentSessions.hooksInstalled && AgentSessions.sessions.length === 0
                        text: Tr.tr("No active sessions")
                        color: Hallownest.subtext
                        font.pointSize: 9
                    }

                    Repeater {
                        model: ScriptModel {
                            values: AgentSessions.sessions.slice(0, 3)
                        }

                        delegate: LiveSession {}
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: Tokens.spacing.medium

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: quick.implicitHeight + Tokens.padding.large * 2

                    radius: Tokens.rounding.extraLarge
                    color: Hallownest.card
                    border.width: 1
                    border.color: Hallownest.border

                    ColumnLayout {
                        id: quick

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.large
                        spacing: Tokens.spacing.medium

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            HkButton {
                                filled: true
                                icon: "terminal"
                                text: Tr.tr("Terminal")
                                disabled: !AiAgents.hasCli
                                onClicked: {
                                    AiAgents.newSession();
                                    root.launched();
                                }
                            }

                            HkButton {
                                visible: AiAgents.hasApp
                                icon: "desktop_windows"
                                text: Tr.tr("App")
                                onClicked: {
                                    AiAgents.openApp();
                                    root.launched();
                                }
                            }

                            HkButton {
                                icon: "history"
                                text: Tr.tr("Continue")
                                disabled: !AiAgents.hasCli
                                onClicked: {
                                    AiAgents.continueSession();
                                    root.launched();
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                height: folderChip.implicitHeight
                                verticalAlignment: Text.AlignVCenter
                                text: "folder"
                                color: Hallownest.subtext
                            }

                            Repeater {
                                model: ScriptModel {
                                    values: AiAgents.directories
                                }

                                delegate: Chip {
                                    required property string modelData

                                    text: AiAgents.dirName(modelData)
                                    selected: modelData === AiAgents.directory
                                    onClicked: AiAgents.directory = modelData
                                }
                            }

                            Chip {
                                id: folderChip

                                icon: "folder_open"
                                text: Tr.tr("Other...")
                                onClicked: {
                                    AiAgents.pickDirectory();
                                    root.screenState.notch = false;
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            HkField {
                                id: promptField

                                Layout.fillWidth: true
                                enabled: AiAgents.hasCli
                                leadingIcon: "auto_awesome"
                                placeholderText: Tr.tr("Ask %1...").arg(AiAgents.provider.name)
                                onAccepted: {
                                    if (!text.trim())
                                        return;
                                    AiAgents.ask(text);
                                    root.launched();
                                }
                                Keys.onEscapePressed: root.screenState.notch = false
                                onActiveFocusChanged: {
                                    if (activeFocus)
                                        root.screenState.notch = true;
                                }
                            }

                            HkButton {
                                filled: true
                                implicitHeight: 28
                                Layout.alignment: Qt.AlignVCenter
                                icon: "send"
                                disabled: !promptField.text.trim()
                                onClicked: promptField.accepted()
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: recent.implicitHeight + Tokens.padding.large * 2

                    radius: Tokens.rounding.extraLarge
                    color: Hallownest.card
                    border.width: 1
                    border.color: Hallownest.border

                    ColumnLayout {
                        id: recent

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.large
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            Layout.leftMargin: Tokens.padding.small
                            Layout.bottomMargin: Tokens.spacing.extraSmall
                            text: Tr.tr("Recent sessions")
                            color: Hallownest.steel
                            font.family: Hallownest.serif
                            font.pointSize: 11
                            font.weight: Font.Bold
                        }

                        StyledText {
                            Layout.leftMargin: Tokens.padding.small
                            visible: AiAgents.sessions.length === 0
                            text: AiAgents.loading ? Tr.tr("Loading...") : Tr.tr("No sessions yet")
                            font: Tokens.font.body.small
                            color: Hallownest.subtext
                        }

                        Repeater {
                            model: ScriptModel {
                                values: AiAgents.sessions.slice(0, 3)
                            }

                            delegate: SessionRow {}
                        }
                    }
                }
            }
        }
    }

    component Chip: StyledRect {
        id: chip

        property string icon
        property string text
        property bool selected

        signal clicked

        implicitWidth: chipRow.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: chipRow.implicitHeight + Tokens.padding.small * 2

        radius: Tokens.rounding.full
        color: selected ? Qt.alpha(Hallownest.lifeblood, 0.18) : "transparent"
        border.width: selected ? 0 : 1
        border.color: Hallownest.border

        StateLayer {
            color: chip.selected ? Hallownest.soul : Hallownest.text
            onClicked: chip.clicked()
        }

        Row {
            id: chipRow

            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: chip.icon || chip.selected
                text: chip.icon || "check"
                color: chip.selected ? Hallownest.soul : Hallownest.subtext
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.text
                font: Tokens.font.label.large
                color: chip.selected ? Hallownest.soul : Hallownest.subtext
            }
        }
    }

    component SessionRow: StyledRect {
        id: row

        required property var modelData

        Layout.fillWidth: true
        implicitHeight: rowLayout.implicitHeight + Tokens.padding.small * 2

        radius: Tokens.rounding.large
        color: "transparent"

        StateLayer {
            color: Hallownest.text
            onClicked: {
                AiAgents.resume(row.modelData);
                root.launched();
            }
        }

        RowLayout {
            id: rowLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: row.modelData.entrypoint === "claude-desktop" ? "desktop_windows" : "terminal"
                color: Hallownest.lifeblood
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: row.modelData.title || row.modelData.prompt || Tr.tr("Untitled session")
                    elide: Text.ElideRight
                    font: Tokens.font.body.medium
                    color: Hallownest.text
                }

                StyledText {
                    Layout.fillWidth: true
                    text: `${AiAgents.prettyPath(row.modelData.cwd)} · ${root.relativeTime(row.modelData.mtime)}`
                    elide: Text.ElideMiddle
                    font: Tokens.font.body.small
                    color: Hallownest.subtext
                }
            }

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: "play_arrow"
                color: Hallownest.subtext
            }
        }
    }

    component LiveSession: StyledRect {
        id: live

        required property var modelData

        readonly property color tone: ({
                thinking: Hallownest.lifeblood,
                working: Hallownest.soul,
                waiting: Hallownest.gold,
                done: Hallownest.unn,
                error: Hallownest.grimm
            })[modelData.state] ?? Hallownest.faint
        readonly property bool busy: modelData.state === "thinking" || modelData.state === "working"
        readonly property string status: {
            const s = modelData;
            switch (s.state) {
            case "thinking":
                return Tr.tr("Thinking...");
            case "working":
                return s.tool ? AgentSessions.describe(s.tool, s.detail) : Tr.tr("Working...");
            case "waiting":
                return Tr.tr("Waiting for you");
            case "done":
                return Tr.tr("Done");
            case "error":
                return Tr.tr("Something went wrong");
            default:
                return Tr.tr("Idle");
            }
        }

        Layout.fillWidth: true
        implicitHeight: liveLayout.implicitHeight + Tokens.padding.medium * 2

        radius: Tokens.rounding.large
        color: Qt.alpha(live.tone, 0.05)
        border.width: 1
        border.color: Qt.alpha(live.tone, live.modelData.state === "waiting" ? 0.5 : 0.18)

        StateLayer {
            color: Hallownest.text
            onClicked: AgentSessions.focusTerminal(live.modelData)
        }

        ColumnLayout {
            id: liveLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.large
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                Rectangle {
                    id: liveDot

                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 8
                    implicitHeight: 8
                    rotation: 45
                    color: live.tone

                    SequentialAnimation on opacity {
                        running: live.busy
                        loops: Animation.Infinite
                        onRunningChanged: {
                            if (!running)
                                liveDot.opacity = 1;
                        }

                        NumberAnimation {
                            to: 0.3
                            duration: 700
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            to: 1
                            duration: 700
                            easing.type: Easing.InOutSine
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: live.modelData.project || "~"
                    elide: Text.ElideRight
                    color: Hallownest.text
                    font.family: Hallownest.serif
                    font.pointSize: 10
                    font.weight: Font.Bold
                }

                MaterialIcon {
                    visible: live.modelData.agent === "claude-desktop"
                    text: "desktop_windows"
                    color: Hallownest.subtext
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    text: root.relativeTime(live.modelData.updated)
                    color: Hallownest.faint
                    font.pointSize: 8
                }

                MaterialIcon {
                    text: "open_in_new"
                    color: Hallownest.subtext
                    fontStyle: Tokens.font.icon.small
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: !!live.modelData.prompt
                text: live.modelData.prompt.replace(/\s+/g, " ")
                elide: Text.ElideRight
                color: Hallownest.subtext
                font.pointSize: 9
            }

            StyledText {
                Layout.fillWidth: true
                text: live.status
                elide: Text.ElideRight
                color: live.tone
                font.pointSize: 9
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                visible: live.modelData.state === "done" && !!live.modelData.message
                text: live.modelData.message.replace(/\s+/g, " ")
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Hallownest.text
                font.pointSize: 9
            }

            Repeater {
                model: live.busy ? live.modelData.steps.slice(-2) : []

                delegate: StyledText {
                    required property string modelData

                    Layout.fillWidth: true
                    text: `· ${modelData}`
                    elide: Text.ElideRight
                    color: Hallownest.faint
                    font.pointSize: 8
                }
            }
        }
    }
}
