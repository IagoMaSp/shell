pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.I18n
import qs.utils

Singleton {
    id: root

    property var current: null
    property bool ready
    property string lastSsid: ""
    property bool wifiReady

    readonly property string wifiSsid: Nmcli.active?.ssid ?? ""

    function show(kind: string, icon: string, text: string, value: real): void {
        if (!ready)
            return;
        current = {
            kind,
            icon,
            text,
            value
        };
        hideTimer.interval = NotchSettings.osdDuration;
        hideTimer.restart();
    }

    function showBattery(title: string, message: string, icon: string, value: real, critical: bool): void {
        if (!ready)
            return;
        current = {
            kind: "battery",
            icon,
            text: title,
            sub: message.replace(/<[^>]+>/g, ""),
            value,
            critical
        };
        hideTimer.interval = critical ? 9000 : 6000;
        hideTimer.restart();
    }

    function volumeIcon(volume: real, muted: bool): string {
        if (muted || volume <= 0)
            return "volume_off";
        return volume > 0.5 ? "volume_up" : "volume_down";
    }

    onWifiSsidChanged: wifiTimer.restart()
    Component.onCompleted: GlobalConfig.utilities.toasts.capsLockChanged = false

    Timer {
        running: true
        interval: 3000
        onTriggered: {
            root.lastSsid = root.wifiSsid;
            root.ready = true;
        }
    }

    Timer {
        running: true
        interval: 20000
        onTriggered: {
            root.lastSsid = root.wifiSsid;
            root.wifiReady = true;
        }
    }

    Timer {
        id: hideTimer

        onTriggered: root.current = null
    }

    Timer {
        id: wifiTimer

        interval: 2000
        onTriggered: {
            if (root.wifiSsid === root.lastSsid || !NotchSettings.values.osdWifi || !root.wifiReady) {
                root.lastSsid = root.wifiSsid;
                return;
            }
            if (root.wifiSsid)
                root.show("wifi", "wifi", Tr.tr("Connected to %1").arg(root.wifiSsid), -1);
            else
                root.show("wifi", "wifi_off", Tr.tr("Wi-Fi disconnected"), -1);
            root.lastSsid = root.wifiSsid;
        }
    }

    Connections {
        function onVolumeChanged(): void {
            if (NotchSettings.values.osdVolume)
                root.show("volume", root.volumeIcon(Audio.volume, Audio.muted), Tr.tr("Volume"), Audio.muted ? 0 : Audio.volume);
        }

        function onMutedChanged(): void {
            onVolumeChanged();
        }

        function onSourceVolumeChanged(): void {
            if (NotchSettings.values.osdMicrophone)
                root.show("mic", Audio.sourceMuted ? "mic_off" : "mic", Tr.tr("Microphone"), Audio.sourceMuted ? 0 : Audio.sourceVolume);
        }

        function onSourceMutedChanged(): void {
            onSourceVolumeChanged();
        }

        target: Audio
    }

    Instantiator {
        model: Brightness.monitors

        Connections {
            required property var modelData

            function onBrightnessChanged(): void {
                if (NotchSettings.values.osdBrightness)
                    root.show("brightness", modelData.brightness > 0.5 ? "brightness_high" : "brightness_low", Tr.tr("Brightness"), modelData.brightness);
            }

            target: modelData
        }
    }

    Connections {
        function onCapsLockChanged(): void {
            if (NotchSettings.values.osdCapsLock)
                root.show("caps", "keyboard_capslock", Hypr.capsLock ? Tr.tr("Caps Lock on") : Tr.tr("Caps Lock off"), -1);
        }

        function onKbLayoutFullChanged(): void {
            if (NotchSettings.values.osdKbLayout)
                root.show("layout", "keyboard", Hypr.kbLayoutFull, -1);
        }

        target: Hypr
    }

    Connections {
        function onOnBatteryChanged(): void {
            if (!NotchSettings.values.osdCharger || !UPower.displayDevice.ready)
                return;
            const perc = Strings.percentOne(UPower.displayDevice.percentage);
            if (UPower.onBattery)
                root.show("charger", "power_off", Tr.tr("Charger unplugged · %1").arg(perc), UPower.displayDevice.percentage);
            else
                root.show("charger", "battery_charging_full", Tr.tr("Charging · %1").arg(perc), UPower.displayDevice.percentage);
        }

        target: UPower
    }

    Instantiator {
        model: Bluetooth.devices

        Connections {
            required property BluetoothDevice modelData

            function onConnectedChanged(): void {
                if (!NotchSettings.values.osdBluetooth)
                    return;
                const name = modelData.name || modelData.deviceName;
                const audio = /head|audio|earbud/i.test(modelData.icon ?? "");
                if (modelData.connected) {
                    const battery = modelData.batteryAvailable ? modelData.battery : -1;
                    root.show("bluetooth", audio ? "headphones" : "bluetooth_connected", name, battery);
                } else {
                    root.show("bluetooth", "bluetooth_disabled", name, -1);
                }
            }

            target: modelData
        }
    }
}
