import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.notch
import qs.modules.notch.pages.calendar

NotchPage {
    id: root

    implicitWidth: 960
    implicitHeight: 400

    RowLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.medium

        StyledRect {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            radius: Tokens.rounding.extraLarge
            color: Hallownest.card

            MonthGrid {
                anchors.verticalCenter: parent.verticalCenter
                screenState: root.screenState
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.extraLarge
            color: Hallownest.card

            Week {
                anchors.fill: parent
            }
        }
    }
}
