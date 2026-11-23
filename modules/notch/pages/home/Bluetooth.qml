pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services
import qs.utils

RowLayout {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool enabled_: adapter?.enabled ?? false
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)

    function status(d: BluetoothDevice): string {
        if (d.state === BluetoothDeviceState.Connecting)
            return Tr.tr("Connecting...");
        if (d.state === BluetoothDeviceState.Disconnecting)
            return Tr.tr("Disconnecting...");
        if (d.connected)
            return d.batteryAvailable ? Tr.tr("Connected · %1%").arg(Math.round(d.battery * 100)) : Tr.tr("Connected");
        return d.paired ? Tr.tr("Paired") : Tr.tr("Available");
    }

    spacing: Tokens.spacing.medium

    Hero {
        icon: !root.enabled_ ? "bluetooth_disabled" : root.connected.length ? "bluetooth_connected" : "bluetooth"
        title: !root.enabled_ ? Tr.tr("Bluetooth off") : root.connected.length === 1 ? root.connected[0].name : root.connected.length ? Tr.tr("%1 connected").arg(root.connected.length) : Tr.tr("Bluetooth")
        subtitle: root.enabled_ ? root.adapter?.name ?? "" : ""
        active: root.enabled_
        accent: Hallownest.lifeblood

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Bluetooth")
                color: Hallownest.text
                font.pointSize: 10
            }

            HkSwitch {
                checked: root.enabled_
                onToggled: c => {
                    if (root.adapter)
                        root.adapter.enabled = c;
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: Tr.trCtx("Discovering", "bluetooth adapter state")
                color: root.enabled_ ? Hallownest.text : Hallownest.faint
                font.pointSize: 10
            }

            HkSwitch {
                checked: root.adapter?.discovering ?? false
                disabled: !root.enabled_
                onToggled: c => {
                    if (root.adapter)
                        root.adapter.discovering = c;
                }
            }
        }
    }

    ListCard {
        title: Tr.tr("Devices")
        info: root.enabled_ ? Tr.trN("%n device", "%n devices", Bluetooth.devices.values.length) : ""

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 220)
            visible: root.enabled_
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: ScriptModel {
                values: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
            }

            delegate: DeviceRow {
                id: device

                required property BluetoothDevice modelData

                width: list.width
                icon: Icons.getBluetoothIcon(modelData.icon)
                text: modelData.name
                subtext: root.status(modelData)
                active: modelData.connected
                busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                accent: Hallownest.lifeblood
                onClicked: modelData.connected = !modelData.connected

                HkButton {
                    visible: device.modelData.bonded
                    opacity: device.hovered ? 1 : 0.35
                    icon: "delete"
                    accent: Hallownest.grimm
                    onClicked: device.modelData.forget()
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: 16
            Layout.bottomMargin: 16
            visible: !root.enabled_ || Bluetooth.devices.values.length === 0
            horizontalAlignment: Text.AlignHCenter
            text: root.enabled_ ? Tr.tr("No devices found") : Tr.tr("Bluetooth is turned off")
            color: Hallownest.faint
            font.family: Hallownest.serif
            font.pointSize: 10
        }
    }
}
