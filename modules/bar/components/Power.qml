import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property ScreenState screenState

    implicitWidth: icon.implicitHeight + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    StateLayer {
        // Cursed workaround to make the height larger than the parent
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small
        radius: Tokens.rounding.full
        onClicked: root.screenState.session = !root.screenState.session
    }

    Rectangle {
        anchors.centerIn: parent
        implicitWidth: icon.implicitHeight + 6
        implicitHeight: implicitWidth
        rotation: 45
        radius: 4
        color: Qt.alpha(Hallownest.grimm, 0.12)
        border.width: 1
        border.color: Qt.alpha(Hallownest.grimm, 0.55)
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: "power_settings_new"
        color: Hallownest.grimm
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()
    }
}
