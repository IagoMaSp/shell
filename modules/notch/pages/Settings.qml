pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.services
import qs.modules.notch

NotchPage {
    id: root

    implicitWidth: 480
    implicitHeight: 420

    StyledFlickable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight
        clip: true

        ColumnLayout {
            id: layout

            width: parent.width
            spacing: 2

            Section {
                first: true
                text: Tr.tr("Appearance")
            }

            Toggle {
                first: true
                key: "mascot"
                text: Tr.tr("Mascot")
                subtext: Tr.tr("Show the Knight when idle")
            }

            Toggle {
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

            Section {
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

            Section {
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
                key: "osdWifi"
                text: Tr.tr("Wi-Fi")
            }

            Toggle {
                key: "osdBluetooth"
                text: Tr.tr("Bluetooth")
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

    component Section: StyledText {
        property bool first

        Layout.topMargin: first ? 0 : Tokens.spacing.large
        Layout.bottomMargin: Tokens.spacing.small
        Layout.leftMargin: Tokens.padding.small
        color: Hallownest.steel
        font.family: Hallownest.serif
        font.pointSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 0.8
    }

    component SettingRow: Rectangle {
        id: row

        property bool first
        property bool last
        property string text
        property string subtext
        default property alias content: trailing.data

        Layout.fillWidth: true
        implicitHeight: Math.max(44, labels.implicitHeight + 16)
        topLeftRadius: first ? 14 : 4
        topRightRadius: first ? 14 : 4
        bottomLeftRadius: last ? 14 : 4
        bottomRightRadius: last ? 14 : 4
        color: Hallownest.card

        ColumnLayout {
            id: labels

            anchors.left: parent.left
            anchors.right: trailing.left
            anchors.leftMargin: Tokens.padding.large
            anchors.rightMargin: Tokens.spacing.medium
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: row.text
                color: Hallownest.text
                font.pointSize: 10
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: row.subtext
                color: Hallownest.subtext
                font.pointSize: 8
                elide: Text.ElideRight
            }
        }

        Row {
            id: trailing

            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding.large
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.small
        }
    }

    component Toggle: SettingRow {
        id: toggle

        required property string key
        readonly property bool checked: NotchSettings.values[key] ?? false

        Rectangle {
            implicitWidth: 38
            implicitHeight: 20
            radius: 10
            color: toggle.checked ? Qt.alpha(Hallownest.lifeblood, 0.35) : Hallownest.button
            border.width: 1
            border.color: toggle.checked ? Qt.alpha(Hallownest.lifeblood, 0.7) : Hallownest.border

            Behavior on color {
                CAnim {}
            }

            Rectangle {
                x: toggle.checked ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 14
                implicitHeight: 14
                rotation: 45
                radius: 2
                color: toggle.checked ? Hallownest.soul : Hallownest.steel

                Behavior on x {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: NotchSettings.set(toggle.key, !toggle.checked)
            }
        }
    }

    component Stepper: SettingRow {
        id: stepper

        required property string key
        property string label
        property real from: 0
        property real to: 99
        property real stepSize: 1
        readonly property real value: NotchSettings.values[key] ?? 0

        function step(dir: int): void {
            const next = Math.round((value + dir * stepSize) / stepSize) * stepSize;
            NotchSettings.set(key, Math.max(from, Math.min(to, Number(next.toFixed(2)))));
        }

        text: label

        HkButton {
            implicitHeight: 24
            icon: "remove"
            disabled: stepper.value <= stepper.from
            onClicked: stepper.step(-1)
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            horizontalAlignment: Text.AlignHCenter
            text: stepper.stepSize < 1 ? stepper.value.toFixed(2) : Math.round(stepper.value)
            color: Hallownest.soul
            font.family: Hallownest.mono
            font.pointSize: 10
            font.weight: Font.Bold
        }

        HkButton {
            implicitHeight: 24
            icon: "add"
            disabled: stepper.value >= stepper.to
            onClicked: stepper.step(1)
        }
    }
}
