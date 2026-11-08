import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.notch

NotchPage {
    id: root

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        spacing: Tokens.spacing.large

        Pomodoro {
            Layout.alignment: Qt.AlignHCenter
            screenState: root.screenState
            page: root.page
        }

        Todo {
            Layout.alignment: Qt.AlignHCenter
            screenState: root.screenState
            page: root.page
        }
    }
}
