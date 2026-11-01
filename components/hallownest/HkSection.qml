import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

StyledText {
    property bool first

    Layout.topMargin: first ? 0 : 14
    Layout.bottomMargin: 6
    Layout.leftMargin: 6
    color: Hallownest.steel
    font.family: Hallownest.serif
    font.pointSize: 10
    font.weight: Font.Bold
    font.letterSpacing: 0.8
}
