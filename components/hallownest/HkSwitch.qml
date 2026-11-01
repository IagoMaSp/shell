import QtQuick
import qs.components
import qs.services

Rectangle {
    id: root

    property bool checked
    property color accent: Hallownest.lifeblood
    property bool disabled

    signal toggled(checked: bool)

    implicitWidth: 38
    implicitHeight: 20
    radius: height / 2
    color: checked ? Qt.alpha(accent, 0.35) : Hallownest.button
    border.width: 1
    border.color: checked ? Qt.alpha(accent, 0.7) : Hallownest.border
    opacity: disabled ? 0.4 : 1

    Behavior on color {
        CAnim {}
    }

    Rectangle {
        x: root.checked ? root.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 14
        implicitHeight: 14
        rotation: 45
        radius: 2
        color: root.checked ? Hallownest.soul : Hallownest.steel

        Behavior on x {
            Anim {
                type: Anim.FastSpatial
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.disabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
