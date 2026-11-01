import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components
import qs.services

Item {
    id: root

    property real radius: 12
    property color colour: Hallownest.soul
    property real pulse
    property real inset: 8

    SequentialAnimation on pulse {
        running: root.visible
        loops: Animation.Infinite

        NumberAnimation {
            to: 1
            duration: 1400
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 0
            duration: 1400
            easing.type: Easing.InOutSine
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Qt.alpha(root.colour, 0.06)
        border.width: 1
        border.color: Qt.alpha(root.colour, 0.14)
    }

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.colour
            shadowOpacity: 0.5 + root.pulse * 0.3
            shadowBlur: 0.6
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 12
        }

        Pointer {
            x: root.inset - root.pulse * 1.5
        }

        Pointer {
            x: root.width - root.inset + root.pulse * 1.5
            mirrored: true
        }
    }

    component Pointer: Shape {
        id: pointer

        property bool mirrored

        y: root.height / 2
        preferredRendererType: Shape.CurveRenderer

        transform: Scale {
            xScale: pointer.mirrored ? -1 : 1
        }

        ShapePath {
            fillColor: root.colour
            strokeWidth: -1

            PathSvg {
                path: "M -4 0 L 0 -4 L 4 0 L 0 4 Z M 5 -1 L 12 -0.4 L 12 0.4 L 5 1 Z"
            }
        }
    }
}
