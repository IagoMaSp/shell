import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components
import qs.services

Item {
    id: root

    property real value
    property color colour: Hallownest.soul
    readonly property bool dragging: area.pressed
    property real dragValue
    readonly property real shown: Math.max(0, Math.min(1, dragging ? dragValue : value))

    signal moved(value: real)

    implicitHeight: 14

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Qt.alpha(Hallownest.steel, 0.18)
    }

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.colour
            shadowBlur: 0.5
            shadowOpacity: 0.6
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 8
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: root.shown * root.width
            height: 4
            radius: 2
            color: root.colour
        }

        Shape {
            x: root.shown * root.width
            y: root.height / 2
            preferredRendererType: Shape.CurveRenderer
            scale: area.containsMouse || root.dragging ? 1.25 : 1

            Behavior on scale {
                Anim {
                    type: Anim.FastSpatial
                }
            }

            ShapePath {
                fillColor: root.colour
                strokeWidth: -1

                PathSvg {
                    path: "M -2 -3.2 L 1 -3.2 L 8 0 L 1 3.2 L -2 3.2 Z"
                }
            }

            ShapePath {
                fillColor: Hallownest.steel
                strokeWidth: -1

                PathSvg {
                    path: "M -3.5 -5 L -1.5 -5 L -1.5 5 L -3.5 5 Z"
                }
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -4
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        onPressed: mouse => root.dragValue = Math.max(0, Math.min(1, (mouse.x - 4) / root.width))
        onPositionChanged: mouse => {
            if (pressed)
                root.dragValue = Math.max(0, Math.min(1, (mouse.x - 4) / root.width));
        }
        onReleased: root.moved(root.dragValue)
    }
}
