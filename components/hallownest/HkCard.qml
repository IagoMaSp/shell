import QtQuick
import qs.services

Rectangle {
    id: root

    property bool ornate

    radius: 14
    color: Hallownest.card
    border.width: 1
    border.color: Hallownest.border

    Filigree {
        anchors.fill: parent
        radius: root.radius
        inset: 5
        opacity: root.ornate ? 0.3 : 0
    }
}
