pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services

// A Claude Code permission request or AskUserQuestion prompt, answered from the notch
StyledRect {
    id: root

    required property var approval
    // Question text -> picked label (single select) or list of labels (multi select)
    property var picks: ({})

    readonly property var session: approval ? AgentSessions.session(approval.sessionId) : null
    readonly property bool asking: (approval?.questions?.length ?? 0) > 0
    readonly property bool complete: asking && approval.questions.every(q => {
        const p = picks[q.question];
        return q.multiSelect ? (p?.length ?? 0) > 0 : !!p;
    })

    function pick(q: var, label: string): void {
        const next = Object.assign({}, picks);
        if (q.multiSelect) {
            const cur = next[q.question] ?? [];
            next[q.question] = cur.includes(label) ? cur.filter(l => l !== label) : cur.concat([label]);
        } else {
            next[q.question] = label;
        }
        picks = next;
    }

    function picked(q: var, label: string): bool {
        const p = picks[q.question];
        return q.multiSelect ? (p ?? []).includes(label) : p === label;
    }

    implicitHeight: content.implicitHeight + Tokens.padding.large * 2

    radius: Tokens.rounding.extraLarge
    color: Qt.alpha(Hallownest.gold, 0.06)
    border.width: 1
    border.color: Qt.alpha(Hallownest.gold, 0.45)

    onApprovalChanged: picks = {}

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4
                implicitWidth: 22
                implicitHeight: 22
                rotation: 45
                color: Qt.alpha(Hallownest.gold, 0.15)
                border.width: 1.2
                border.color: Hallownest.gold

                MaterialIcon {
                    anchors.centerIn: parent
                    rotation: -45
                    text: root.asking ? "question_mark" : "shield"
                    color: Hallownest.gold
                    fontStyle: Tokens.font.icon.small
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                spacing: 0

                StyledText {
                    text: root.asking ? Tr.tr("Claude asks") : Tr.tr("Claude needs your permission")
                    color: Hallownest.gold
                    font.family: Hallownest.serif
                    font.pointSize: 11
                    font.weight: Font.Bold
                }

                StyledText {
                    Layout.fillWidth: true
                    text: [root.session?.project, root.asking ? "" : root.approval?.tool].filter(x => !!x).join(" · ")
                    elide: Text.ElideRight
                    color: Hallownest.subtext
                    font.pointSize: 9
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                visible: AgentSessions.approvals.length > 1
                text: Tr.tr("+%1 more").arg(AgentSessions.approvals.length - 1)
                color: Hallownest.subtext
                font.pointSize: 9
            }
        }

        StyledRect {
            Layout.fillWidth: true
            visible: !root.asking && !!root.approval?.detail
            implicitHeight: detail.implicitHeight + Tokens.padding.medium * 2

            radius: Tokens.rounding.large
            color: Hallownest.void_
            border.width: 1
            border.color: Hallownest.border

            StyledText {
                id: detail

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                text: root.approval?.detail ?? ""
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 6
                elide: Text.ElideRight
                color: Hallownest.text
                font.family: Hallownest.mono
                font.pointSize: 9
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: !root.asking && !!root.approval?.description
            text: root.approval?.description ?? ""
            wrapMode: Text.WordWrap
            color: Hallownest.subtext
            font.pointSize: 9
        }

        Repeater {
            model: root.asking ? root.approval.questions : []

            delegate: ColumnLayout {
                id: question

                required property var modelData

                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        visible: !!question.modelData.header
                        text: (question.modelData.header ?? "").toUpperCase()
                        color: Hallownest.steel
                        font.family: Hallownest.serif
                        font.pointSize: 8
                        font.weight: Font.Bold
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: question.modelData.question ?? ""
                        wrapMode: Text.WordWrap
                        color: Hallownest.text
                        font.pointSize: 10
                        font.weight: Font.DemiBold
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: question.modelData.options ?? []

                        delegate: OptionChip {
                            required property var modelData

                            text: modelData.label
                            multi: question.modelData.multiSelect ?? false
                            selected: root.picked(question.modelData, modelData.label)
                            onClicked: root.pick(question.modelData, modelData.label)
                        }
                    }
                }

                StyledText {
                    readonly property var chosen: (question.modelData.options ?? []).find(o => root.picked(question.modelData, o.label))

                    Layout.fillWidth: true
                    visible: !question.modelData.multiSelect && !!chosen?.description
                    text: chosen?.description ?? ""
                    wrapMode: Text.WordWrap
                    color: Hallownest.subtext
                    font.pointSize: 9
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            HkButton {
                implicitHeight: 28
                icon: "terminal"
                text: Tr.tr("Terminal")
                onClicked: {
                    AgentSessions.focusTerminal(root.session);
                    AgentSessions.skip(root.approval.id);
                }
            }

            Item {
                Layout.fillWidth: true
            }

            HkButton {
                implicitHeight: 28
                visible: !root.asking
                icon: "close"
                text: Tr.tr("Deny")
                accent: Hallownest.grimm
                tinted: true
                onClicked: AgentSessions.deny(root.approval.id)
            }

            HkButton {
                implicitHeight: 28
                visible: !root.asking && (root.approval?.canAlways ?? false)
                icon: "done_all"
                text: Tr.tr("Always")
                accent: Hallownest.gold
                tinted: true
                onClicked: AgentSessions.always(root.approval.id)
            }

            HkButton {
                implicitHeight: 28
                visible: !root.asking
                filled: true
                icon: "check"
                text: Tr.tr("Allow")
                onClicked: AgentSessions.allow(root.approval.id)
            }

            HkButton {
                implicitHeight: 28
                visible: root.asking
                filled: true
                icon: "send"
                text: Tr.tr("Answer")
                disabled: !root.complete
                onClicked: AgentSessions.answer(root.approval.id, root.picks)
            }
        }
    }

    component OptionChip: StyledRect {
        id: chip

        property string text
        property bool selected
        property bool multi

        signal clicked

        implicitWidth: chipRow.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: chipRow.implicitHeight + Tokens.padding.small * 2

        radius: Tokens.rounding.full
        color: selected ? Qt.alpha(Hallownest.gold, 0.18) : "transparent"
        border.width: 1
        border.color: selected ? Qt.alpha(Hallownest.gold, 0.6) : Hallownest.border

        StateLayer {
            color: chip.selected ? Hallownest.gold : Hallownest.text
            onClicked: chip.clicked()
        }

        Row {
            id: chipRow

            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                rotation: chip.multi ? 0 : 45
                radius: chip.multi ? 2 : 0
                color: chip.selected ? Hallownest.gold : "transparent"
                border.width: 1
                border.color: chip.selected ? Hallownest.gold : Hallownest.steel
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.text
                color: chip.selected ? Hallownest.soul : Hallownest.text
                font.pointSize: 10
            }
        }
    }
}
