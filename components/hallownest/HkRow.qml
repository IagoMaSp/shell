import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Rectangle {
    id: root

    property bool first
    property bool last
    property string text
    property string subtext
    property string icon
    default property alias content: trailing.data

    Layout.fillWidth: true
    implicitHeight: Math.max(44, labels.implicitHeight + 16)
    topLeftRadius: first ? 14 : 4
    topRightRadius: first ? 14 : 4
    bottomLeftRadius: last ? 14 : 4
    bottomRightRadius: last ? 14 : 4
    color: Hallownest.card

    MaterialIcon {
        id: leading

        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        visible: root.icon !== ""
        text: root.icon
        color: Hallownest.subtext
    }

    ColumnLayout {
        id: labels

        anchors.left: leading.visible ? leading.right : parent.left
        anchors.right: trailing.left
        anchors.leftMargin: leading.visible ? 10 : 14
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            text: root.text
            color: Hallownest.text
            font.pointSize: 10
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.subtext
            color: Hallownest.subtext
            font.pointSize: 8
            elide: Text.ElideRight
        }
    }

    Row {
        id: trailing

        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
    }
}
