pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services
import qs.utils

Item {
    id: root

    required property HyprlandMonitor monitor
    readonly property real monX: monitor?.lastIpcObject.x ?? 0
    readonly property real monY: monitor?.lastIpcObject.y ?? 0
    readonly property real monW: (monitor?.width ?? 1920) / (monitor?.scale ?? 1)
    readonly property real monH: (monitor?.height ?? 1080) / (monitor?.scale ?? 1)

    readonly property int columns: 5
    readonly property int count: {
        let max = Math.max(columns, Hypr.activeWsId);
        for (const t of Hypr.toplevels.values)
            if ((t.workspace?.id ?? 0) > max)
                max = t.workspace.id;
        return Math.min(20, Math.ceil(max / columns) * columns);
    }
    readonly property real cardW: Math.min(340, (width - Tokens.padding.extraLarge * 4 - Tokens.spacing.large * (columns - 1)) / columns)
    readonly property real cardH: cardW * monH / monW
    property int selected: Hypr.activeWsId - 1
    property var dragWindow: null
    property int draggingWs: -1
    property string pendingRequest

    signal close

    // Dispatch after the overlay drops keyboard focus, otherwise Hyprland refocuses the previous window
    function closeThen(request: string): void {
        pendingRequest = request;
        close();
        dispatchTimer.restart();
    }

    function goTo(ws: int): void {
        closeThen(Hypr.usingLua ? `hl.dsp.focus({ workspace = "${ws}" })` : `workspace ${ws}`);
    }

    function focusWindow(t: var): void {
        closeThen(Hypr.usingLua ? `hl.dsp.focus({ window = "address:0x${t.address}" })` : `focuswindow address:0x${t.address}`);
    }

    function moveWindow(t: var, ws: int): void {
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.move({ window = "address:0x${t.address}", workspace = "${ws}", follow = false })` : `movetoworkspacesilent ${ws},address:0x${t.address}`);
        Qt.callLater(() => Hyprland.refreshToplevels());
    }

    function killWindow(t: var): void {
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.kill({ window = "address:0x${t.address}" })` : `killwindow address:0x${t.address}`);
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels();
        forceActiveFocus();
    }

    focus: true
    Keys.onEscapePressed: close()
    Keys.onReturnPressed: goTo(selected + 1)
    Keys.onEnterPressed: goTo(selected + 1)
    Keys.onLeftPressed: selected = Math.max(0, selected - 1)
    Keys.onRightPressed: selected = Math.min(count - 1, selected + 1)
    Keys.onUpPressed: selected = Math.max(0, selected - columns)
    Keys.onDownPressed: selected = Math.min(count - 1, selected + columns)
    Keys.onPressed: event => {
        const n = parseInt(event.text);
        if (!isNaN(n)) {
            goTo(n === 0 ? 10 : n);
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab) {
            selected = (selected + 1) % count;
            event.accepted = true;
        }
    }

    Timer {
        id: dispatchTimer

        interval: 60
        onTriggered: Hypr.dispatch(root.pendingRequest)
    }

    // Backdrop, click to close
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Hallownest.void_, 0.94)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Tokens.spacing.extraLarge

        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: root.columns
            columnSpacing: Tokens.spacing.large
            rowSpacing: Tokens.spacing.large

            Repeater {
                model: root.count

                WorkspaceCard {}
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Tr.tr("Click to go · Drag windows between workspaces · Middle click closes a window")
            color: Hallownest.faint
            font.pointSize: 9
        }
    }

    component WorkspaceCard: Item {
        id: card

        required property int index
        readonly property int wsId: index + 1
        readonly property bool active: Hypr.activeWsId === wsId
        readonly property bool isSelected: root.selected === index
        readonly property var windows: Hypr.toplevels.values.filter(t => t.workspace?.id === wsId && t.lastIpcObject?.mapped !== false && t.lastIpcObject?.at)
        readonly property real scale: root.cardW / root.monW

        z: root.draggingWs === wsId ? 10 : 0
        Layout.preferredWidth: root.cardW
        Layout.preferredHeight: root.cardH + label.implicitHeight + Tokens.spacing.small

        StyledText {
            id: label

            anchors.left: parent.left
            anchors.leftMargin: 4
            text: card.wsId
            color: card.active ? Hallownest.soul : Hallownest.subtext
            font.family: Hallownest.serif
            font.pointSize: 11
            font.weight: Font.Bold
        }

        Rectangle {
            id: frame

            anchors.bottom: parent.bottom
            width: root.cardW
            height: root.cardH
            radius: 12
            color: dropArea.containsDrag ? Qt.alpha(Hallownest.soul, 0.08) : Hallownest.card
            border.width: card.active || card.isSelected || dropArea.containsDrag ? 1.5 : 1
            border.color: card.active ? Hallownest.soul : card.isSelected || dropArea.containsDrag ? Qt.alpha(Hallownest.soul, 0.5) : Hallownest.border
            clip: root.draggingWs !== card.wsId

            Behavior on border.color {
                CAnim {}
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.selected = card.index
                onClicked: root.goTo(card.wsId)
            }

            HealthMask {
                anchors.centerIn: parent
                visible: card.windows.length === 0
                size: 26
                opacity: 0.3
            }

            DropArea {
                id: dropArea

                anchors.fill: parent
                keys: ["overview-window"]
                onDropped: {
                    if (root.dragWindow && root.dragWindow.workspace?.id !== card.wsId)
                        root.moveWindow(root.dragWindow, card.wsId);
                }
            }

            Repeater {
                model: card.windows

                Item {
                    id: win

                    required property var modelData
                    readonly property var ipc: modelData.lastIpcObject
                    readonly property real baseX: (ipc.at[0] - root.monX) * card.scale
                    readonly property real baseY: (ipc.at[1] - root.monY) * card.scale

                    x: baseX
                    y: baseY
                    z: ipc.floating ? 2 : 1
                    width: Math.max(12, ipc.size[0] * card.scale)
                    height: Math.max(12, ipc.size[1] * card.scale)

                    Drag.active: winMouse.drag.active
                    Drag.keys: ["overview-window"]
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: Hallownest.shell
                        border.width: 1
                        border.color: winMouse.containsMouse ? Hallownest.soul : Qt.alpha(Hallownest.steel, 0.3)
                        clip: true

                        ScreencopyView {
                            id: copy

                            anchors.fill: parent
                            anchors.margins: 1
                            captureSource: win.modelData.wayland ?? null
                            live: true
                        }

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: Math.min(28, parent.height * 0.4)
                            source: Icons.getAppIcon(win.ipc.class ?? "", "image-missing")
                            visible: !copy.hasContent
                        }
                    }

                    MouseArea {
                        id: winMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                        drag.target: win
                        drag.threshold: 6

                        onEntered: root.selected = card.index
                        onPositionChanged: {
                            if (drag.active)
                                root.draggingWs = card.wsId;
                        }
                        onPressed: event => {
                            if (event.button === Qt.LeftButton) {
                                root.dragWindow = win.modelData;
                                win.z = 10;
                            }
                        }
                        onReleased: {
                            if (drag.active)
                                win.Drag.drop();
                            root.draggingWs = -1;
                            win.x = Qt.binding(() => win.baseX);
                            win.y = Qt.binding(() => win.baseY);
                            win.z = Qt.binding(() => win.ipc.floating ? 2 : 1);
                        }
                        onClicked: event => {
                            if (event.button === Qt.MiddleButton)
                                root.killWindow(win.modelData);
                            else
                                root.focusWindow(win.modelData);
                        }
                    }
                }
            }
        }
    }
}
