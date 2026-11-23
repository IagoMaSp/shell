import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property bool checked
    property color colour: Hallownest.soul

    signal clicked

    implicitWidth: 22
    implicitHeight: 22

    Rectangle {
        anchors.centerIn: parent
        implicitWidth: 15
        implicitHeight: 15
        radius: 7.5
        color: root.checked ? root.colour : "transparent"
        border.width: 1.5
        border.color: root.colour
        scale: area.pressed ? 0.85 : 1

        Behavior on color {
            CAnim {}
        }

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: root.checked
            text: "check"
            color: Hallownest.void_
            fontStyle: Tokens.font.icon.small
            scale: 0.75
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
