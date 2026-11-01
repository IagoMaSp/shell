pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.notch

NotchPage {
    id: root

    readonly property bool focusMode: Pomodoro.mode === "focus"
    readonly property color accent: focusMode ? Hallownest.infection : Hallownest.lifeblood

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout

        spacing: Tokens.spacing.extraLarge

        SoulVessel {
            Layout.margins: 6
            level: 1 - Pomodoro.progress
            colour: root.accent
            running: Pomodoro.running
        }

        ColumnLayout {
            spacing: Tokens.spacing.small

            RowLayout {
                spacing: Tokens.spacing.medium

                StyledText {
                    text: Pomodoro.remainingStr
                    color: Hallownest.soul
                    font.family: Hallownest.serif
                    font.pointSize: 28
                    font.weight: Font.Bold
                }

                ColumnLayout {
                    spacing: 0

                    StyledText {
                        text: root.focusMode ? Tr.tr("Focus") : Tr.tr("Break")
                        color: root.accent
                        font.pointSize: 10
                        font.weight: Font.DemiBold

                        Behavior on color {
                            CAnim {}
                        }
                    }

                    StyledText {
                        text: Tr.tr("%1 today").arg(Pomodoro.completedToday)
                        color: Hallownest.subtext
                        font.pointSize: 9
                    }
                }
            }

            RowLayout {
                spacing: Tokens.spacing.small

                HkButton {
                    icon: "restart_alt"
                    disabled: !Pomodoro.active
                    onClicked: Pomodoro.reset()
                }

                HkButton {
                    icon: Pomodoro.running ? "pause" : "play_arrow"
                    text: Pomodoro.running ? Tr.tr("Pause") : Pomodoro.active ? Tr.tr("Resume") : Tr.tr("Start")
                    filled: true
                    onClicked: Pomodoro.toggle()
                }

                HkButton {
                    icon: root.focusMode ? "psychology" : "coffee"
                    text: root.focusMode ? Tr.tr("Focus time") : Tr.tr("Short break")
                    accent: root.accent
                    tinted: true
                    onClicked: Pomodoro.setMode(root.focusMode ? "break" : "focus")
                }

                HkButton {
                    icon: "skip_next"
                    onClicked: Pomodoro.skip()
                }
            }
        }
    }
}
