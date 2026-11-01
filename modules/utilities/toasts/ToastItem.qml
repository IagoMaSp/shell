import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.effects
import qs.services

StyledRect {
    id: root

    required property Toast modelData
    readonly property color accent: {
        if (modelData.type === Toast.Success)
            return Hallownest.unn;
        if (modelData.type === Toast.Warning)
            return Hallownest.gold;
        if (modelData.type === Toast.Error)
            return Hallownest.grimm;
        return Hallownest.soul;
    }

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: layout.implicitHeight + Tokens.padding.large

    radius: 14
    color: Hallownest.void_
    border.width: 1
    border.color: Qt.alpha(accent, modelData.type === Toast.Info ? 0.2 : 0.45)

    Elevation {
        anchors.fill: parent
        radius: parent.radius
        opacity: parent.opacity
        z: -1
        level: 3
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.large

        Item {
            implicitWidth: icon.implicitHeight + 10
            implicitHeight: implicitWidth

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.78
                height: width
                rotation: 45
                radius: 4
                color: Qt.alpha(root.accent, 0.12)
                border.width: 1
                border.color: Qt.alpha(root.accent, 0.5)
            }

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: root.modelData.icon
                color: root.accent
                fontStyle: Tokens.font.icon.medium
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: title

                Layout.fillWidth: true
                text: Tr.trMarked(root.modelData.title)
                color: root.modelData.type === Toast.Info ? Hallownest.soul : root.accent
                font.family: Hallownest.serif
                font.pointSize: 11
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                text: Tr.trMarked(root.modelData.message)
                color: Hallownest.subtext
                font.pointSize: 9
                elide: Text.ElideRight
            }
        }
    }

    Behavior on border.color {
        CAnim {}
    }
}
