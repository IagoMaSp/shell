import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.hallownest
import qs.services

// Left summary card of the Home detail views: glowing icon, title and status
HkCard {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool active
    property color accent: Hallownest.soul
    default property alias content: extra.data

    Layout.preferredWidth: 210
    Layout.fillHeight: true
    implicitHeight: column.implicitHeight + 32
    ornate: true

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 16
        spacing: 6

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 4
            implicitWidth: 56
            implicitHeight: 56
            radius: 28
            color: root.active ? Qt.alpha(root.accent, 0.14) : Hallownest.button
            border.width: 1
            border.color: root.active ? Qt.alpha(root.accent, 0.6) : Hallownest.border

            Behavior on color {
                CAnim {}
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: root.icon
                color: root.active ? root.accent : Hallownest.subtext
                fill: root.active ? 1 : 0
                fontStyle: Tokens.font.icon.extraLarge
            }
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.title
            color: root.active ? Hallownest.soul : Hallownest.subtext
            font.family: Hallownest.serif
            font.pointSize: 11
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: text !== ""
            text: root.subtitle
            color: Hallownest.subtext
            font.pointSize: 8
            elide: Text.ElideRight
        }

        ColumnLayout {
            id: extra

            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 6
        }
    }
}
