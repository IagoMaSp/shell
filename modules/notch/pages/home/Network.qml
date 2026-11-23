pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.hallownest
import qs.services
import qs.utils

RowLayout {
    id: root

    property var screenState
    property string connecting
    property string passwordFor
    property string failed
    readonly property var active: Nmcli.active

    function band(freq: int): string {
        return freq >= 4900 ? "5 GHz" : freq > 0 ? "2.4 GHz" : "";
    }

    function connect(network: var): void {
        failed = "";
        if (network.active) {
            Nmcli.disconnectFromNetwork();
            return;
        }
        passwordFor = "";
        connecting = network.ssid;
        connectTimeout.restart();
        NetworkConnection.handleConnect(network, null, n => {
            connecting = "";
            passwordFor = n.ssid;
        });
    }

    function submitPassword(network: var, password: string): void {
        if (!password)
            return;
        connecting = network.ssid;
        connectTimeout.restart();
        NetworkConnection.connectWithPassword(network, password, result => {
            if (result?.success)
                return;
            connecting = "";
            failed = network.ssid;
            Nmcli.forgetNetwork(network.ssid);
        });
    }

    spacing: Tokens.spacing.medium

    Connections {
        function onActiveChanged(): void {
            if (Nmcli.active && Nmcli.active.ssid === root.connecting) {
                root.connecting = "";
                root.passwordFor = "";
            }
        }

        target: Nmcli
    }

    Timer {
        id: connectTimeout

        interval: 25000
        onTriggered: root.connecting = ""
    }

    Hero {
        icon: Nmcli.activeEthernet ? "lan" : !Nmcli.wifiEnabled ? "wifi_off" : root.active ? Icons.getNetworkIcon(root.active.strength) : "wifi_find"
        title: Nmcli.activeEthernet ? Tr.tr("Ethernet") : !Nmcli.wifiEnabled ? Tr.tr("Wi-Fi off") : root.active?.ssid ?? Tr.tr("Not connected")
        subtitle: Nmcli.activeEthernet ? (Nmcli.activeEthernet.iface ?? "") : root.active ? [`${root.active.strength}%`, root.band(root.active.frequency)].filter(s => s).join(" · ") : ""
        active: !!root.active || !!Nmcli.activeEthernet
        accent: Hallownest.lifeblood

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Wi-Fi")
                color: Hallownest.text
                font.pointSize: 10
            }

            HkSwitch {
                checked: Nmcli.wifiEnabled
                onToggled: c => Nmcli.enableWifi(c)
            }
        }

        HkButton {
            Layout.fillWidth: true
            visible: !!root.active
            icon: "link_off"
            text: Tr.tr("Disconnect")
            accent: Hallownest.grimm
            tinted: true
            onClicked: Nmcli.disconnectFromNetwork()
        }
    }

    ListCard {
        title: Tr.tr("Networks")
        info: Nmcli.wifiEnabled ? Tr.trN("%n available", "%n available", Nmcli.networks.length) : ""
        actions: [
            Item {
                implicitWidth: 30
                implicitHeight: 30
                visible: Nmcli.wifiEnabled

                CircularIndicator {
                    anchors.centerIn: parent
                    implicitSize: 18
                    strokeWidth: 2
                    fgColour: Hallownest.lifeblood
                    bgColour: "transparent"
                    running: Nmcli.scanning
                    visible: Nmcli.scanning
                }

                HkButton {
                    anchors.fill: parent
                    visible: !Nmcli.scanning
                    icon: "refresh"
                    onClicked: Nmcli.rescanWifi()
                }
            }
        ]

        Repeater {
            model: ScriptModel {
                values: [...Nmcli.ethernetDevices].sort((a, b) => b.connected - a.connected)
            }

            DeviceRow {
                required property var modelData

                icon: "cable"
                text: modelData.iface || Tr.trCtx("Unknown", "unknown network interface")
                subtext: modelData.connected ? Tr.tr("Connected") : Tr.tr("Ethernet")
                active: modelData.connected
                accent: Hallownest.lifeblood
                onClicked: {
                    if (modelData.connected && modelData.connection)
                        Nmcli.disconnectEthernet(modelData.connection, () => {});
                    else
                        Nmcli.connectEthernet(modelData.connection || "", modelData.iface || "", () => {});
                }
            }
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 220)
            visible: Nmcli.wifiEnabled
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: ScriptModel {
                values: [...Nmcli.networks].sort((a, b) => (b.active - a.active) || (b.strength - a.strength))
            }

            delegate: ColumnLayout {
                id: item

                required property Nmcli.AccessPoint modelData
                readonly property bool asking: root.passwordFor === modelData.ssid

                width: list.width
                spacing: 4

                onAskingChanged: {
                    password.text = "";
                    if (asking)
                        password.forceActiveFocus();
                }

                DeviceRow {
                    icon: Icons.getNetworkIcon(item.modelData.strength)
                    text: item.modelData.ssid
                    subtext: [root.failed === item.modelData.ssid ? Tr.tr("Couldn't connect") : item.modelData.active ? Tr.tr("Connected") : root.connecting === item.modelData.ssid ? Tr.tr("Connecting...") : Nmcli.hasSavedProfile(item.modelData.ssid) ? Tr.tr("Saved") : item.modelData.isSecure ? Tr.tr("Secured") : Tr.tr("Open"), root.band(item.modelData.frequency)].filter(s => s).join(" · ")
                    active: item.modelData.active
                    busy: root.connecting === item.modelData.ssid
                    accent: Hallownest.lifeblood
                    onClicked: root.connect(item.modelData)

                    MaterialIcon {
                        visible: item.modelData.isSecure
                        text: "lock"
                        color: Hallownest.faint
                        fontStyle: Tokens.font.icon.small
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    Layout.rightMargin: 4
                    Layout.bottomMargin: 4
                    visible: item.asking
                    spacing: 6

                    HkField {
                        id: password

                        Layout.fillWidth: true
                        leadingIcon: "key"
                        placeholderText: Tr.tr("Password")
                        echoMode: TextInput.Password
                        onActiveFocusChanged: {
                            // The notch must stay open while typing
                            if (activeFocus && root.screenState)
                                root.screenState.notch = true;
                        }
                        onAccepted: root.submitPassword(item.modelData, text)
                        Keys.onEscapePressed: root.passwordFor = ""
                    }

                    HkButton {
                        icon: "close"
                        onClicked: root.passwordFor = ""
                    }

                    HkButton {
                        icon: "arrow_forward"
                        filled: true
                        disabled: password.text === ""
                        onClicked: root.submitPassword(item.modelData, password.text)
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: 16
            Layout.bottomMargin: 16
            visible: !Nmcli.wifiEnabled
            horizontalAlignment: Text.AlignHCenter
            text: Tr.tr("Wi-Fi is turned off")
            color: Hallownest.faint
            font.family: Hallownest.serif
            font.pointSize: 10
        }
    }
}
