import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.notch

NotchPage {
    id: root

    implicitWidth: 360
    implicitHeight: column.implicitHeight + Tokens.padding.large * 2

    Column {
        id: column

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.page?.icon ?? ""
            color: Hallownest.lifeblood
            fontStyle: Tokens.font.icon.extraLarge
        }

        StyledText {
            color: Hallownest.text
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.page?.label ?? ""
            font: Tokens.font.title.medium
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Tr.tr("Coming soon")
            color: Hallownest.subtext
            font: Tokens.font.body.small
        }
    }
}
