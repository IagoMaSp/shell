import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Row {
    id: root

    readonly property var nextEvent: {
        if (!NotchSettings.values.nextEvent)
            return null;
        const now = clock.date;
        const mins = now.getHours() * 60 + now.getMinutes();
        const toMins = t => {
            const [h, m] = (t || "").split(":").map(n => parseInt(n));
            return isNaN(h) ? -1 : h * 60 + (m || 0);
        };
        for (const e of Events.eventsOn(now)) {
            if (e.allDay)
                continue;
            const start = toMins(e.start);
            if (start < 0)
                continue;
            if (start > mins && start - mins <= NotchSettings.values.nextEventLead)
                return Object.assign({
                    inMins: start - mins
                }, e);
        }
        return null;
    }

    function loadToday(): void {
        const start = new Date(clock.date.getFullYear(), clock.date.getMonth(), clock.date.getDate());
        const end = new Date(start);
        end.setDate(end.getDate() + 1);
        Events.loadRange("notch", start, end);
    }

    spacing: Tokens.spacing.medium

    Component.onCompleted: loadToday()

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
        onDateChanged: {
            if (date.getHours() === 0 && date.getMinutes() === 0)
                root.loadToday();
        }
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

    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: !!root.nextEvent
        spacing: Tokens.spacing.extraSmall

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "school"
            color: Hallownest.gold
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 160)
            text: root.nextEvent?.title ?? ""
            color: Hallownest.text
            font.pointSize: 9
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                const e = root.nextEvent;
                if (!e)
                    return "";
                const where = e.location ? ` · ${e.location}` : "";
                return Tr.tr("in %1 min").arg(e.inMins) + where;
            }
            color: Hallownest.subtext
            font.pointSize: 9
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: AgentSessions.busy || AgentSessions.approvals.length > 0
        spacing: Tokens.spacing.small

        Rectangle {
            id: agentDot

            anchors.verticalCenter: parent.verticalCenter
            width: 7
            height: 7
            rotation: 45
            color: AgentSessions.approvals.length > 0 ? Hallownest.gold : Hallownest.lifeblood

            SequentialAnimation on opacity {
                running: AgentSessions.busy && root.visible
                loops: Animation.Infinite
                onRunningChanged: {
                    if (!running)
                        agentDot.opacity = 1;
                }

                NumberAnimation {
                    to: 0.3
                    duration: 700
                    easing.type: Easing.InOutSine
                }

                NumberAnimation {
                    to: 1
                    duration: 700
                    easing.type: Easing.InOutSine
                }
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: AgentSessions.busyCount > 1 ? `Claude ×${AgentSessions.busyCount}` : "Claude"
            color: Hallownest.text
            font.pointSize: 9
            font.weight: Font.DemiBold
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: Recorder.running
        spacing: Tokens.spacing.extraSmall

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: 8
            radius: 4
            color: Hallownest.grimm
            opacity: Recorder.paused ? 0.4 : 1
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Recorder.elapsedText()
            color: Hallownest.grimm
            font.family: Hallownest.mono
            font.pointSize: 9
            font.weight: Font.DemiBold
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: Privacy.micInUse || Privacy.cameraInUse
        spacing: 2

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: Privacy.micInUse
            text: "mic"
            color: Hallownest.grimm
            fill: 1
            fontStyle: Tokens.font.icon.small
        }

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: Privacy.cameraInUse
            text: "videocam"
            color: Hallownest.grimm
            fill: 1
            fontStyle: Tokens.font.icon.small
        }
    }

    MiniEqualizer {
        anchors.verticalCenter: parent.verticalCenter
        visible: NotchMedia.player?.isPlaying ?? false
        running: visible && root.visible
    }
}
