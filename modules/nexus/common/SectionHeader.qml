import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledText {
    property bool first

    Layout.fillWidth: true
    Layout.topMargin: first ? 0 : Tokens.spacing.largeIncreased - ((parent as ColumnLayout).spacing ?? 0)
    Layout.bottomMargin: Tokens.spacing.extraSmall
    Layout.leftMargin: Tokens.padding.small

    color: Hallownest.steel
    font.family: Hallownest.serif
    font.pointSize: Tokens.font.label.medium.pointSize + 1
    font.weight: Font.Bold
    font.letterSpacing: 0.8
    elide: Text.ElideRight
}
