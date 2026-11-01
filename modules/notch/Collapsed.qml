import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Row {
    id: root

    spacing: Tokens.spacing.medium

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.locale().toString(clock.date, NotchSettings.twelveHour ? "h:mm AP" : "HH:mm")
        color: Hallownest.soul
        font.family: Hallownest.mono
        font.pointSize: 11
        font.weight: Font.Bold
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        visible: NotchSettings.showDate
        text: Qt.locale().toString(clock.date, "ddd d")
        color: Hallownest.subtext
        font.pointSize: 9
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: Pomodoro.active
        spacing: Tokens.spacing.extraSmall

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: Pomodoro.mode === "focus" ? "psychology" : "coffee"
            color: Pomodoro.mode === "focus" ? Hallownest.infection : Hallownest.lifeblood
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Pomodoro.remainingStr
            color: Pomodoro.running ? Hallownest.soul : Hallownest.faint
            font.family: Hallownest.mono
            font.pointSize: 10
            font.weight: Font.Bold
        }
    }

    MiniEqualizer {
        anchors.verticalCenter: parent.verticalCenter
        visible: NotchMedia.player?.isPlaying ?? false
        running: visible && root.visible
    }
}
