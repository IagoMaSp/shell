import QtQuick
import Quickshell.Services.UPower
import qs.components
import qs.components.hallownest
import qs.services

Item {
    id: root

    required property color colour
    readonly property bool laptop: UPower.displayDevice.isLaptopBattery
    readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)
    readonly property real level: UPower.displayDevice.percentage

    implicitWidth: laptop ? 17 : icon.implicitWidth
    implicitHeight: laptop ? 17 : icon.implicitHeight

    SoulVessel {
        anchors.centerIn: parent
        implicitWidth: 15
        implicitHeight: 15
        visible: root.laptop
        ornate: false
        level: root.level
        colour: root.charging ? Hallownest.lifeblood : root.level <= 0.2 ? Hallownest.grimm : Hallownest.soul
        running: root.charging
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        visible: !root.laptop
        animate: true
        text: {
            if (PowerProfiles.profile === PowerProfile.PowerSaver)
                return "energy_savings_leaf";
            if (PowerProfiles.profile === PowerProfile.Performance)
                return "rocket_launch";
            return "balance";
        }
        color: root.colour
        fill: 1
    }
}
