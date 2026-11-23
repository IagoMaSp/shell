import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Rectangle {
    id: root

    property string icon
    property string text
    property string subtext
    property bool active
    property bool busy
    property color accent: Hallownest.soul
    readonly property bool hovered: area.containsMouse
    default property alias content: trailing.data

    signal clicked

    Layout.fillWidth: true
    implicitHeight: 42
    radius: 12
    color: active ? Qt.alpha(accent, hovered ? 0.2 : 0.13) : hovered ? Hallownest.button : "transparent"
    border.width: 1
    border.color: active ? Qt.alpha(accent, 0.5) : hovered ? Hallownest.border : "transparent"

    Behavior on color {
        CAnim {}
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 10

        Item {
            implicitWidth: 22
            implicitHeight: 22

            MaterialIcon {
                anchors.centerIn: parent
                visible: !root.busy
                text: root.icon
                color: root.active ? root.accent : Hallownest.subtext
                fill: root.active ? 1 : 0
            }

            CircularIndicator {
                anchors.centerIn: parent
                implicitSize: 20
                strokeWidth: 2
                fgColour: root.accent
                bgColour: "transparent"
                running: root.busy
                visible: root.busy
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.text
                color: root.active ? Hallownest.soul : Hallownest.text
                font.pointSize: 10
                font.weight: root.active ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtext
                color: root.active ? Qt.alpha(root.accent, 0.85) : Hallownest.subtext
                font.pointSize: 8
                elide: Text.ElideRight
            }
        }

        Row {
            id: trailing

            spacing: 8
        }
    }
}
