import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.hallownest
import qs.services

// Right card of the Home detail views: Cinzel header with extra actions and a list below
HkCard {
    id: root

    property string title
    property string info
    property alias actions: actionRow.data
    default property alias content: body.data

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: column.implicitHeight + 20

    ColumnLayout {
        id: column

        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.minimumHeight: 30
            spacing: 8

            StyledText {
                text: root.title
                color: Hallownest.steel
                font.family: Hallownest.serif
                font.pointSize: 10
                font.weight: Font.Bold
            }

            StyledText {
                Layout.fillWidth: true
                text: root.info
                color: Hallownest.faint
                font.pointSize: 8
                elide: Text.ElideRight
            }

            Row {
                id: actionRow

                spacing: 6
            }
        }

        ColumnLayout {
            id: body

            Layout.fillWidth: true
            spacing: 2
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
