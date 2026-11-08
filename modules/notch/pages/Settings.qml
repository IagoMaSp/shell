pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.hallownest
import qs.services
import qs.modules.notch

NotchPage {
    id: root

    implicitWidth: 560
    implicitHeight: 420

    StyledFlickable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight
        clip: true

        ColumnLayout {
            id: layout

            width: parent.width
            spacing: 2

            HkSection {
                first: true
                text: Tr.tr("Theme")
            }

            HkRow {
                first: true
                last: true
                text: Tr.tr("Flavour")
                subtext: Tr.tr("Hollow Knight palette for the whole shell")

                Repeater {
                    model: [
                        {
                            id: "vessel",
                            colour: Hallownest.soul
                        },
                        {
                            id: "lifeblood",
                            colour: Hallownest.lifeblood
                        },
                        {
                            id: "infection",
                            colour: Hallownest.infection
                        },
                        {
                            id: "greenpath",
                            colour: Hallownest.unn
                        }
                    ]

                    HkButton {
                        required property var modelData

                        implicitHeight: 26
                        text: modelData.id.charAt(0).toUpperCase() + modelData.id.slice(1)
                        accent: modelData.colour
                        tinted: Hallownest.flavour === modelData.id
                        onClicked: Hallownest.setFlavour(modelData.id)
                    }
                }
            }

            HkSection {
                text: Tr.tr("Animations")
            }

            Toggle {
                first: true
                key: "mascot"
                text: Tr.tr("Mascot")
                subtext: Tr.tr("Show the Knight when idle")
            }

            Toggle {
                key: "animBench"
                text: Tr.tr("Bench rest")
                subtext: Tr.tr("Darken before locking and the Knight on the bench in the lock screen")
            }

            Toggle {
                key: "animWeather"
                text: Tr.tr("Weather scenes")
                subtext: Tr.tr("Animated landscape in the Weather page")
            }

            Toggle {
                key: "animSeasons"
                text: Tr.tr("Seasons")
                subtext: Tr.tr("Grimm embers in October and snow in December")
            }

            Toggle {
                key: "animTyping"
                text: Tr.tr("Dialogue typing")
                subtext: Tr.tr("Notifications are typed out like an NPC")
            }

            Toggle {
                last: true
                key: "animGoo"
                text: Tr.tr("Island and dock transition")
                subtext: Tr.tr("Drops travel along the frame when switching modes")
            }

            HkSection {
                text: Tr.tr("Appearance")
            }

            Toggle {
                first: true
                key: "mascotRandom"
                text: Tr.tr("Random visits")
                subtext: Tr.tr("The Knight drops by now and then")
            }

            Toggle {
                key: "mascotTracking"
                text: Tr.tr("Follow the cursor")
                subtext: Tr.tr("The Knight's eyes follow the mouse")
            }

            Toggle {
                key: "mascotReactions"
                text: Tr.tr("Reactions")
                subtext: Tr.tr("The Knight reacts to battery, music, Wi-Fi, pomodoro and tasks")
            }

            Toggle {
                key: "minimal"
                text: Tr.tr("Minimal notch")
                subtext: Tr.tr("Collapse to a thin line")
            }

            Toggle {
                key: "twelveHour"
                text: Tr.tr("12-hour clock")
            }

            Toggle {
                key: "showDate"
                text: Tr.tr("Show date")
            }

            Stepper {
                key: "scale"
                label: Tr.tr("Scale")
                from: 0.7
                to: 1.6
                stepSize: 0.05
            }

            Stepper {
                key: "mascotDelay"
                label: Tr.tr("Mascot delay")
                subtext: Tr.tr("Minutes idle before the mascot appears")
                from: 1
                to: 60
            }

            Stepper {
                last: true
                key: "dozeDelay"
                label: Tr.tr("Doze delay")
                subtext: Tr.tr("Minutes idle before the mascot falls asleep")
                from: 1
                to: 120
            }

            HkSection {
                text: Tr.tr("Productivity")
            }

            Stepper {
                first: true
                key: "pomodoroFocus"
                label: Tr.tr("Focus time")
                subtext: Tr.tr("Minutes")
                from: 1
                to: 120
            }

            Stepper {
                key: "pomodoroBreak"
                label: Tr.tr("Short break")
                subtext: Tr.tr("Minutes")
                from: 1
                to: 60
            }

            Stepper {
                last: true
                key: "snoozeMinutes"
                label: Tr.tr("Snooze")
                subtext: Tr.tr("Minutes")
                from: 1
                to: 60
            }

            HkSection {
                text: Tr.tr("AI agents")
            }

            HkRow {
                first: true
                text: Tr.tr("Claude Code hooks")
                subtext: AgentSessions.hooksInstalled ? Tr.tr("Live sessions and approvals in the notch") : Tr.tr("Adds hooks to ~/.claude/settings.json (with a backup)")

                HkButton {
                    implicitHeight: 26
                    icon: AgentSessions.hooksInstalled ? "link_off" : "add_link"
                    text: AgentSessions.hooksInstalled ? Tr.tr("Remove") : Tr.tr("Install")
                    accent: AgentSessions.hooksInstalled ? Hallownest.grimm : Hallownest.lifeblood
                    tinted: true
                    disabled: AgentSessions.hooksBusy
                    onClicked: AgentSessions.installHooks(!AgentSessions.hooksInstalled)
                }
            }

            Toggle {
                key: "agentAlerts"
                text: Tr.tr("Approvals in the notch")
                subtext: Tr.tr("Allow or deny Claude's requests from the collapsed notch")
            }

            Toggle {
                last: true
                key: "agentOsd"
                text: Tr.tr("Finished sessions")
                subtext: Tr.tr("Show an overlay when Claude finishes")
            }

            HkSection {
                text: Tr.tr("System overlays")
            }

            Toggle {
                first: true
                key: "osdVolume"
                text: Tr.tr("Volume")
            }

            Toggle {
                key: "osdMicrophone"
                text: Tr.tr("Microphone")
            }

            Toggle {
                key: "osdBrightness"
                text: Tr.tr("Brightness")
            }

            Toggle {
                key: "osdCapsLock"
                text: Tr.tr("Caps Lock")
            }

            Toggle {
                key: "osdKbLayout"
                text: Tr.tr("Keyboard layout")
            }

            Toggle {
                key: "osdCharger"
                text: Tr.tr("Charger")
            }

            Toggle {
                key: "osdBattery"
                text: Tr.tr("Low battery")
            }

            Toggle {
                key: "osdWifi"
                text: Tr.tr("Wi-Fi")
            }

            Toggle {
                key: "osdBluetooth"
                text: Tr.tr("Bluetooth")
            }

            Toggle {
                key: "notifsInNotch"
                text: Tr.tr("Notifications")
            }

            Toggle {
                key: "nextEvent"
                text: Tr.tr("Next class")
            }

            Stepper {
                last: true
                key: "osdDuration"
                label: Tr.tr("Overlay duration")
                subtext: Tr.tr("Milliseconds")
                from: 500
                to: 6000
                stepSize: 100
            }
        }
    }

    component Toggle: HkRow {
        id: toggle

        required property string key

        HkSwitch {
            checked: NotchSettings.values[toggle.key] ?? false
            onToggled: checked => NotchSettings.set(toggle.key, checked)
        }
    }

    component Stepper: HkRow {
        id: stepper

        required property string key
        property string label
        property real from: 0
        property real to: 99
        property real stepSize: 1

        text: label

        HkStepper {
            value: NotchSettings.values[stepper.key] ?? 0
            from: stepper.from
            to: stepper.to
            stepSize: stepper.stepSize
            onMoved: value => NotchSettings.set(stepper.key, value)
        }
    }
}
