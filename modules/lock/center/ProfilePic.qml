pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Caelestia.Multimedia
import qs.components.hallownest
import qs.services
import qs.utils

Item {
    id: root

    required property int centerWidth
    readonly property real diameter: Math.round(centerWidth * 0.5)

    implicitWidth: Math.round(centerWidth * 0.7)
    implicitHeight: diameter + 28

    Rectangle {
        id: ring

        anchors.centerIn: parent
        width: root.diameter + 18
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Hallownest.steel, 0.3)

        Repeater {
            model: 4

            Rectangle {
                required property int index
                readonly property real angle: index * Math.PI / 2 - Math.PI / 2

                x: ring.width / 2 + Math.cos(angle) * ring.width / 2 - width / 2
                y: ring.height / 2 + Math.sin(angle) * ring.height / 2 - height / 2
                width: 7
                height: 7
                rotation: 45
                color: Hallownest.steel
            }
        }
    }

    ClippingRectangle {
        id: frame

        anchors.centerIn: parent
        width: root.diameter
        height: width
        radius: width / 2
        color: Hallownest.card
        border.width: 2
        border.color: Qt.alpha(Hallownest.soul, 0.45)

        HealthMask {
            anchors.centerIn: parent
            size: root.diameter * 0.62
            glow: true
            visible: !pfp.ready
        }

        Visual {
            id: pfp

            anchors.fill: parent
            source: `${Paths.home}/.face`
        }
    }
}
