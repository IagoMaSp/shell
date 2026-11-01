import QtQuick
import QtQuick.Shapes
import QtQuick.Templates
import Caelestia.Config
import qs.components
import qs.services

Switch {
    id: root

    property int cLayer: 1
    property bool disabled

    enabled: !disabled

    implicitWidth: implicitIndicatorWidth
    implicitHeight: implicitIndicatorHeight

    indicator: Rectangle {
        implicitWidth: 38
        implicitHeight: 20
        radius: height / 2
        color: {
            if (root.disabled)
                return Qt.alpha(Hallownest.button, 0.5);
            return root.checked ? Qt.alpha(Hallownest.lifeblood, 0.35) : Hallownest.button;
        }
        border.width: 1
        border.color: root.checked && !root.disabled ? Qt.alpha(Hallownest.lifeblood, 0.7) : Hallownest.border
        opacity: root.disabled ? 0.5 : 1

        Behavior on color {
            CAnim {}
        }

        Rectangle {
            x: root.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: root.pressed ? 16 : 14
            implicitHeight: implicitWidth
            rotation: 45
            radius: 2
            color: root.checked ? Hallownest.soul : Hallownest.steel
            opacity: root.hovered && !root.pressed ? 0.85 : 1

            Behavior on x {
                Anim {
                    type: Anim.FastSpatial
                }
            }

            Behavior on implicitWidth {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: false
    }

    component PropAnim: PropertyAnimation {
        duration: Tokens.anim.durations.expressiveFastSpatial
        easing: Tokens.anim.expressiveFastSpatial
    }
}
