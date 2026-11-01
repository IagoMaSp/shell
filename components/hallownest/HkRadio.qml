import QtQuick
import qs.components
import qs.services

Item {
    id: root

    property bool checked
    property string text
    property color accent: Hallownest.soul

    signal clicked

    implicitWidth: diamond.width + label.implicitWidth + 14
    implicitHeight: Math.max(26, label.implicitHeight + 6)

    Rectangle {
        id: diamond

        anchors.left: parent.left
        anchors.leftMargin: 3
        anchors.verticalCenter: parent.verticalCenter
        width: 11
        height: 11
        rotation: 45
        color: "transparent"
        border.width: 1.2
        border.color: root.checked ? root.accent : Qt.alpha(Hallownest.steel, 0.7)

        Rectangle {
            anchors.centerIn: parent
            width: root.checked ? 5 : 0
            height: width
            color: root.accent

            Behavior on width {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }
    }

    StyledText {
        id: label

        anchors.left: diamond.right
        anchors.leftMargin: 11
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: root.checked ? Hallownest.soul : Hallownest.text
        font.pointSize: 10
        font.weight: root.checked ? Font.DemiBold : Font.Normal
        elide: Text.ElideRight
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
