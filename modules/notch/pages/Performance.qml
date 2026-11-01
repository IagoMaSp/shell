pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.notch

NotchPage {
    id: root

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ServiceRef {
        service: Cpu
    }

    ServiceRef {
        service: Gpu
    }

    ServiceRef {
        service: Memory
    }

    ServiceRef {
        service: Storage
    }

    ServiceRef {
        service: NetworkUsage
    }

    ColumnLayout {
        id: layout

        spacing: Tokens.spacing.medium

        RowLayout {
            spacing: Tokens.spacing.medium

            Gauge {
                icon: "memory"
                label: Tr.tr("CPU")
                value: Cpu.percentage
                detail: Units.formatSensorTemp(Cpu.temperature)
                accent: Hallownest.lifeblood
            }

            Gauge {
                visible: Gpu.type !== GpuType.None
                icon: "desktop_windows"
                label: Tr.tr("GPU")
                value: Gpu.percentage
                detail: Units.formatSensorTemp(Gpu.temperature)
                accent: Hallownest.crystal
            }

            Gauge {
                icon: "memory_alt"
                label: Tr.tr("RAM")
                value: Memory.percentage
                detail: Units.formatKibUsage(Memory.used, Memory.total)
                accent: Hallownest.gold
            }

            Gauge {
                icon: "hard_drive"
                label: Tr.tr("Disk")
                value: Storage.primaryDisk?.perc ?? 0
                detail: Storage.primaryDisk ? Units.formatKibUsage(Storage.primaryDisk.used, Storage.primaryDisk.total) : "--"
                accent: Hallownest.unn
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Chip {
                icon: "download"
                text: Units.formatBytes(NetworkUsage.downloadSpeed ?? 0, true)
                accent: Hallownest.lifeblood
            }

            Chip {
                icon: "upload"
                text: Units.formatBytes(NetworkUsage.uploadSpeed ?? 0, true)
                accent: Hallownest.crystal
            }

            Chip {
                visible: UPower.displayDevice.isLaptopBattery
                icon: UPower.onBattery ? "battery_full" : "battery_charging_full"
                text: Strings.percentOne(UPower.displayDevice.percentage)
                accent: Hallownest.gold
            }
        }
    }

    component Gauge: StyledRect {
        id: gauge

        property string icon
        property string label
        property real value
        property string detail
        property color accent

        implicitWidth: 150
        implicitHeight: gaugeColumn.implicitHeight + Tokens.padding.large * 2
        radius: 14
        color: Hallownest.card
        border.width: 1
        border.color: Hallownest.border

        ColumnLayout {
            id: gaugeColumn

            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            CircularProgress {
                Layout.alignment: Qt.AlignHCenter
                implicitSize: 84
                value: gauge.value
                fgColour: gauge.accent
                bgColour: Qt.alpha(Hallownest.steel, 0.15)
                strokeWidth: 8

                Column {
                    anchors.centerIn: parent

                    MaterialIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: gauge.icon
                        color: gauge.accent
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        color: Hallownest.text
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Strings.percentOne(gauge.value)
                        font: Tokens.font.title.small
                    }
                }
            }

            StyledText {
                color: Hallownest.text
                Layout.alignment: Qt.AlignHCenter
                text: gauge.label
                font: Tokens.font.label.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 130
                text: gauge.detail
                color: Hallownest.subtext
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }
    }

    component Chip: StyledRect {
        id: chip

        property string icon
        property string text
        property color accent

        Layout.fillWidth: true
        implicitHeight: chipRow.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: Hallownest.card

        Row {
            id: chipRow

            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.icon
                color: chip.accent
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                color: Hallownest.text
                anchors.verticalCenter: parent.verticalCenter
                text: chip.text
                font: Tokens.font.body.small
            }
        }
    }
}
