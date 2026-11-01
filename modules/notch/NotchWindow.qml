pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.hallownest
import qs.services
import qs.modules.notch.mascot
import qs.modules.notch.pages as Pages

StyledWindow {
    id: root

    readonly property ScreenState screenState: ShellState.forScreen(screen)
    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool hasSpecialWorkspace: (monitor?.lastIpcObject.specialWorkspace?.name.length ?? 0) > 0
    readonly property bool hasFullscreen: {
        if (hasSpecialWorkspace) {
            const specialName = monitor?.lastIpcObject.specialWorkspace?.name;
            const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
            return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
        }
        return monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
    }

    readonly property int pageCount: NotchPages.pages.length
    readonly property int pageIndex: Math.max(0, Math.min(screenState.notchPage, pageCount - 1))
    readonly property var page: NotchPages.pages[pageIndex]
    readonly property var pageComponents: ({
            media: mediaPage,
            calendar: calendarPage,
            weather: weatherPage,
            performance: performancePage,
            ai: aiPage,
            pomodoro: pomodoroPage,
            todo: todoPage,
            shelf: shelfPage,
            settings: settingsPage
        })

    property bool hovered
    property bool dragHovered
    readonly property bool expanded: !hasFullscreen && (hovered || dragHovered || screenState.notch || Shelf.dragging)
    readonly property bool alertShown: Todos.alert !== null && !expanded && !hasFullscreen && Hypr.focusedMonitor?.name === screen.name
    readonly property bool osdShown: NotchOsd.current !== null && !alertShown && !expanded && !hasFullscreen && Hypr.focusedMonitor?.name === screen.name
    readonly property bool richOsd: osdShown && ["bluetooth", "charger", "battery"].includes(NotchOsd.current?.kind)
    readonly property bool minimal: NotchSettings.minimal && !expanded && !osdShown && !alertShown
    readonly property bool mascotAllowed: NotchSettings.mascot && !hasFullscreen && !expanded && !minimal && !Pomodoro.running && !Todos.alert && Notifs.popups.length === 0
    property bool mascotShown
    property bool visiting
    readonly property bool canReact: mascotAllowed && !osdShown && !alertShown && Hypr.focusedMonitor?.name === screen.name
    readonly property bool islandShown: NotchMedia.lyricsActive && !hasFullscreen && !minimal && (expanded ? page.id === "media" : (NotchMedia.player?.isPlaying ?? false) && Lyrics.hasLyrics)

    readonly property bool active: (NotchMedia.player?.isPlaying ?? false) || Pomodoro.running
    property color glowColour: active ? Qt.alpha(Hallownest.lifeblood, 0.4) : Qt.alpha("black", 0.75)

    property real wheelAccum
    property bool cursorMoving
    property real lastCursorX: -1
    property real lastCursorY: -1
    property real lastCursorMove

    function goTo(index: int): void {
        screenState.notchPage = (index + pageCount) % pageCount;
    }

    function step(delta: int): void {
        goTo(pageIndex + delta);
    }

    function updateLook(x: real, y: real): void {
        const p = knight.mapToItem(null, knight.width / 2, knight.height * 0.65);
        const gx = screen.x + (screen.width - width) / 2 + p.x;
        const gy = screen.y + p.y;
        knight.targetX = Math.max(-1, Math.min(1, (x - gx) / 260));
        knight.targetY = Math.max(-1, Math.min(1, (y - gy) / 200));
        const now = Date.now();
        if (lastCursorX >= 0 && Math.hypot(x - lastCursorX, y - lastCursorY) > 2)
            lastCursorMove = now;
        lastCursorX = x;
        lastCursorY = y;
        cursorMoving = now - lastCursorMove < 2000;
    }

    function playReaction(): void {
        if (!canReact || !Mascot.pending)
            return;
        const name = Mascot.take();
        if (!name)
            return;
        if (!mascotShown) {
            visiting = true;
            mascotShown = true;
        }
        if (visiting) {
            visitEnd.interval = 6000;
            visitEnd.restart();
        }
        knight.react(name);
    }

    onCanReactChanged: playReaction()
    onIslandShownChanged: NotchMedia.positionUsers += islandShown ? 1 : -1
    onMascotAllowedChanged: {
        if (!mascotAllowed) {
            mascotShown = false;
            visiting = false;
        } else if (shortIdle.isIdle) {
            mascotShown = true;
        }
    }
    onHasFullscreenChanged: {
        if (hasFullscreen) {
            screenState.notch = false;
            hovered = false;
        }
    }

    name: "notch"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region {
        item: root.hasFullscreen ? null : container

        Region {
            item: island.visible ? island : null
        }
    }

    anchors.top: true
    implicitWidth: Math.min(screen.width, 1280)
    implicitHeight: Math.min(screen.height, 860)

    Behavior on glowColour {
        CAnim {
            duration: 900
        }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
        enabled: root.expanded
    }

    HyprlandFocusGrab {
        active: root.screenState.notch
        windows: [root]
        onCleared: root.screenState.notch = false
    }

    IdleMonitor {
        id: shortIdle

        enabled: NotchSettings.mascot
        respectInhibitors: false
        timeout: NotchSettings.mascotDelay * 60

        onIsIdleChanged: {
            if (isIdle && root.mascotAllowed) {
                root.mascotShown = true;
                root.visiting = false;
            } else if (!isIdle && root.mascotShown && !root.visiting) {
                knight.wake();
            }
        }
    }

    IdleMonitor {
        id: longIdle

        enabled: NotchSettings.mascot
        respectInhibitors: false
        timeout: NotchSettings.dozeDelay * 60
    }

    Connections {
        function onDraggingChanged(): void {
            if (!Shelf.dragging && !hoverHandler.hovered)
                leaveTimer.restart();
        }

        target: Shelf
    }

    Socket {
        id: cursorSocket

        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/hypr/${Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")}/.socket.sock`

        parser: SplitParser {
            splitMarker: "}"
            onRead: data => {
                const m = /"x":\s*(-?[\d.]+),\s*"y":\s*(-?[\d.]+)/.exec(data);
                if (m)
                    root.updateLook(parseFloat(m[1]), parseFloat(m[2]));
                cursorSocket.connected = false;
            }
        }

        onConnectedChanged: {
            if (connected) {
                write("j/cursorpos");
                flush();
            }
        }
    }

    Timer {
        running: knight.visible && knight.running && NotchSettings.values.mascotTracking && !knight.dozing
        interval: 60
        repeat: true
        onTriggered: {
            if (!cursorSocket.connected)
                cursorSocket.connected = true;
        }
    }

    Connections {
        function onCurrentChanged(): void {
            if (NotchOsd.current?.icon === "battery_charging_full" && Hypr.focusedMonitor?.name === root.screen.name)
                flashAnim.restart();
        }

        target: NotchOsd
    }

    Connections {
        function onPendingChanged(): void {
            Qt.callLater(root.playReaction);
        }

        target: Mascot
    }

    Connections {
        function onMascotCallsChanged(): void {
            if (!NotchSettings.mascot || !root.mascotAllowed || root.mascotShown)
                return;
            root.visiting = true;
            root.mascotShown = true;
            visitEnd.interval = 15000;
            visitEnd.restart();
        }

        target: root.screenState
    }

    Timer {
        id: visitTimer

        running: NotchSettings.mascot && NotchSettings.values.mascotRandom && root.mascotAllowed && !root.mascotShown
        interval: 90000
        onTriggered: {
            interval = 60000 + Math.random() * 120000;
            root.visiting = true;
            root.mascotShown = true;
            visitEnd.interval = 12000 + Math.random() * 18000;
            visitEnd.restart();
        }
    }

    Timer {
        id: visitEnd

        onTriggered: {
            if (knight.reacting) {
                interval = 1500;
                restart();
                return;
            }
            if (root.visiting && root.mascotShown)
                knight.leave();
        }
    }

    Timer {
        id: enterTimer

        interval: 80
        onTriggered: {
            if (root.alertShown)
                return;
            if (root.mascotShown)
                knight.wake();
            else
                root.hovered = true;
        }
    }

    Timer {
        id: leaveTimer

        interval: 250
        onTriggered: root.hovered = false
    }

    Item {
        id: container

        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: shape.width * NotchSettings.scale
        implicitHeight: Config.border.thickness + pill.height * NotchSettings.scale
        opacity: root.hasFullscreen ? 0 : 1
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        HoverHandler {
            id: hoverHandler

            onHoveredChanged: {
                if (hovered) {
                    leaveTimer.stop();
                    if (!root.hovered)
                        enterTimer.restart();
                } else {
                    enterTimer.stop();
                    leaveTimer.restart();
                }
            }
        }

        DropArea {
            anchors.fill: parent
            keys: ["text/uri-list", "text/plain"]
            onEntered: {
                root.dragHovered = true;
                if (!Shelf.dragging)
                    root.goTo(NotchPages.pages.findIndex(p => p.id === "shelf"));
            }
            onExited: root.dragHovered = false
            onDropped: drop => {
                root.dragHovered = false;
                if (Shelf.dragging)
                    return;
                if (drop.hasUrls)
                    Shelf.addUrls(drop.urls);
                else if (drop.hasText)
                    Shelf.addText(drop.text);
                drop.accept(Qt.CopyAction);
            }
        }

        Item {
            y: Config.border.thickness
            width: shape.width
            height: pill.height
            scale: NotchSettings.scale
            transformOrigin: Item.TopLeft

            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 32
                    shadowBlur: 1
                    shadowVerticalOffset: 3
                    shadowColor: root.glowColour
                }

                IslandShape {
                    id: shape

                    w: pill.width
                    h: pill.height
                    radius: pill.radius
                    leftFillet: root.minimal ? 6 : 14
                    rightFillet: root.islandShown ? 4 : root.minimal ? 6 : 14
                }
            }

            Item {
                id: pill

                property real radius: root.expanded ? 26 : Math.min(height / 2, 14)
                readonly property real padding: Tokens.padding.large
                readonly property real collapsedHeight: root.alertShown ? 52 : root.mascotShown && !root.osdShown ? 46 : root.osdShown ? (root.richOsd ? 64 : 40) : 34
                readonly property real collapsedWidth: {
                    if (root.alertShown)
                        return alertView.implicitWidth + padding * 2;
                    if (root.osdShown)
                        return root.richOsd ? Math.max(270, richView.implicitWidth + padding * 2) : Math.max(260, osdView.implicitWidth + padding * 2);
                    if (root.mascotShown)
                        return knight.implicitWidth + padding * 2.5;
                    return Math.max(140, collapsed.implicitWidth + padding * 2);
                }

                x: shape.leftFillet
                width: {
                    if (root.expanded)
                        return Math.max(collapsedWidth, (pageLoader.item?.implicitWidth ?? 0) + padding * 2, header.minWidth + padding * 2);
                    if (root.minimal)
                        return 160;
                    return collapsedWidth;
                }
                height: {
                    if (root.expanded)
                        return (pageLoader.item?.implicitHeight ?? 0) + header.implicitHeight + Tokens.spacing.medium + padding * 2;
                    if (root.minimal)
                        return 6;
                    return collapsedHeight;
                }

                Behavior on width {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }

                Behavior on height {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }

                Behavior on radius {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    enabled: root.expanded

                    onWheel: wheel => {
                        const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : -wheel.angleDelta.x;
                        root.wheelAccum += delta;
                        if (Math.abs(root.wheelAccum) >= 120) {
                            root.step(root.wheelAccum > 0 ? -1 : 1);
                            root.wheelAccum = 0;
                        }
                    }
                }

                Filigree {
                    anchors.fill: parent
                    radius: pill.radius
                    opacity: root.expanded ? 0.22 : 0
                }

                Collapsed {
                    id: collapsed

                    anchors.centerIn: parent
                    opacity: !root.expanded && !root.minimal && !root.mascotShown && !root.osdShown && !root.alertShown ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                RowLayout {
                    id: alertView

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.medium
                    opacity: root.alertShown ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    MaterialIcon {
                        text: "alarm"
                        color: Hallownest.grimm
                        fontStyle: Tokens.font.icon.large
                    }

                    ColumnLayout {
                        spacing: 0

                        StyledText {
                            text: Tr.tr("Time's up!")
                            color: Hallownest.grimm
                            font.family: Hallownest.serif
                            font.pointSize: 10
                            font.weight: Font.Bold
                        }

                        StyledText {
                            Layout.maximumWidth: 260
                            text: Todos.alert?.title ?? ""
                            color: Hallownest.soul
                            font.pointSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    HkButton {
                        icon: "snooze"
                        text: Tr.tr("Snooze")
                        accent: Hallownest.gold
                        tinted: true
                        onClicked: Todos.snooze(Todos.alert.id)
                    }

                    HkButton {
                        icon: "check"
                        filled: true
                        onClicked: Todos.toggle(Todos.alert.id)
                    }

                    HkButton {
                        icon: "close"
                        onClicked: Todos.dismissAlert()
                    }
                }

                Row {
                    id: osdView

                    readonly property var info: NotchOsd.current
                    readonly property real value: info?.value ?? -1

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.medium
                    opacity: root.osdShown && !root.richOsd ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: osdView.info?.icon ?? ""
                        color: Hallownest.lifeblood
                        fontStyle: Tokens.font.icon.medium
                        animate: true
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 320)
                        text: osdView.info?.text ?? ""
                        color: Hallownest.soul
                        font.pointSize: 10
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    StyledRect {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: osdView.value >= 0
                        implicitWidth: 120
                        implicitHeight: 4
                        radius: 2
                        color: Qt.alpha(Hallownest.steel, 0.18)

                        StyledRect {
                            implicitWidth: parent.width * Math.max(0, Math.min(1, osdView.value))
                            implicitHeight: parent.height
                            radius: 2
                            color: Hallownest.lifeblood

                            Behavior on implicitWidth {
                                Anim {
                                    type: Anim.FastSpatial
                                }
                            }
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: osdView.value >= 0 && ["volume", "mic", "brightness"].includes(osdView.info?.kind)
                        text: Math.round(osdView.value * 100)
                        color: Hallownest.subtext
                        font.family: Hallownest.mono
                        font.pointSize: 9
                    }
                }

                Item {
                    id: richView

                    readonly property var info: NotchOsd.current
                    readonly property bool charger: info?.kind === "charger" || info?.kind === "battery"
                    readonly property bool low: info?.kind === "battery"
                    readonly property bool plugged: info?.icon === "battery_charging_full"
                    readonly property bool connected: info?.icon !== "bluetooth_disabled"
                    readonly property real value: info?.value ?? -1

                    anchors.centerIn: parent
                    implicitWidth: charger ? chargerRow.implicitWidth : btRow.implicitWidth
                    implicitHeight: 44
                    opacity: root.richOsd ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    RowLayout {
                        id: btRow

                        anchors.centerIn: parent
                        visible: !richView.charger
                        spacing: Tokens.spacing.medium

                        Rectangle {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: 20
                            color: Qt.alpha(richView.connected ? Hallownest.lifeblood : Hallownest.steel, 0.18)
                            border.width: 1
                            border.color: Qt.alpha(richView.connected ? Hallownest.lifeblood : Hallownest.steel, 0.5)

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: richView.info?.icon ?? ""
                                color: richView.connected ? Hallownest.lifeblood : Hallownest.subtext
                                fontStyle: Tokens.font.icon.medium
                                fill: 1
                            }
                        }

                        ColumnLayout {
                            spacing: 0

                            StyledText {
                                Layout.maximumWidth: 220
                                text: richView.info?.text ?? ""
                                color: Hallownest.soul
                                font.pointSize: 11
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            StyledText {
                                text: {
                                    if (!richView.connected)
                                        return Tr.tr("Disconnected");
                                    if (richView.value >= 0)
                                        return Tr.tr("Connected · %1%").arg(Math.round(richView.value * 100));
                                    return Tr.tr("Connected");
                                }
                                color: richView.connected ? Hallownest.lifebloodSoft : Hallownest.subtext
                                font.pointSize: 9
                            }
                        }
                    }

                    RowLayout {
                        id: chargerRow

                        anchors.centerIn: parent
                        visible: richView.charger
                        spacing: Tokens.spacing.extraLarge

                        ColumnLayout {
                            spacing: 0

                            StyledText {
                                Layout.maximumWidth: 260
                                text: richView.low ? richView.info.text : richView.plugged ? Tr.tr("Soul Restoring") : Tr.tr("On battery")
                                color: richView.low && richView.info.critical ? Hallownest.grimm : Hallownest.soul
                                elide: Text.ElideRight
                                font.family: Hallownest.serif
                                font.pointSize: 11
                                font.weight: Font.Bold
                            }

                            StyledText {
                                Layout.maximumWidth: 260
                                text: richView.low ? richView.info.sub : richView.plugged ? Tr.tr("Charger connected") : Tr.tr("Charger disconnected")
                                color: richView.low ? Hallownest.infection : richView.plugged ? Hallownest.lifebloodSoft : Hallownest.subtext
                                elide: Text.ElideRight
                                font.pointSize: 9
                            }
                        }

                        Row {
                            spacing: Tokens.spacing.small

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: `${Math.round(Math.max(0, richView.value) * 100)}%`
                                color: Hallownest.soul
                                font.family: Hallownest.serif
                                font.pointSize: 17
                                font.weight: Font.Bold
                            }

                            Item {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: 30
                                implicitHeight: 14
                                layer.enabled: richView.plugged
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: Hallownest.crystal
                                    shadowBlur: 0.8
                                    shadowHorizontalOffset: 0
                                    shadowVerticalOffset: 0
                                    blurMax: 12
                                }

                                Rectangle {
                                    width: 27
                                    height: 14
                                    radius: 3.5
                                    color: "transparent"
                                    border.width: 1.5
                                    border.color: richView.plugged ? Hallownest.soul : Hallownest.steel

                                    Rectangle {
                                        x: 2.5
                                        y: 2.5
                                        width: Math.max(2, (parent.width - 5) * Math.max(0, Math.min(1, richView.value)))
                                        height: parent.height - 5
                                        radius: 1.5
                                        color: richView.plugged ? Hallownest.soul : richView.value < 0.2 ? Hallownest.grimm : Hallownest.steel
                                    }
                                }

                                Rectangle {
                                    x: 28
                                    y: 4.5
                                    width: 2
                                    height: 5
                                    radius: 1
                                    color: richView.plugged ? Hallownest.soul : Hallownest.steel
                                }
                            }
                        }
                    }
                }

                Shape {
                    id: benchFlash

                    property real progress: 1

                    anchors.fill: parent
                    visible: progress < 1
                    opacity: 1 - progress
                    preferredRendererType: Shape.CurveRenderer

                    NumberAnimation on progress {
                        id: flashAnim

                        running: false
                        from: 0
                        to: 1
                        duration: 1100
                        easing.type: Easing.OutCubic
                    }

                    ShapePath {
                        strokeWidth: -1
                        fillGradient: RadialGradient {
                            centerX: pill.width / 2
                            centerY: pill.height / 2
                            centerRadius: 20 + benchFlash.progress * pill.width * 0.6
                            focalX: centerX
                            focalY: centerY

                            GradientStop {
                                position: 0
                                color: Qt.alpha(Hallownest.soul, 0.85)
                            }
                            GradientStop {
                                position: 0.45
                                color: Qt.alpha(Hallownest.crystal, 0.35)
                            }
                            GradientStop {
                                position: 1
                                color: "transparent"
                            }
                        }

                        PathRectangle {
                            width: pill.width
                            height: pill.height
                            radius: pill.radius
                        }
                    }
                }

                Knight {
                    id: knight

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    size: 48
                    dozing: longIdle.isIdle && !root.visiting
                    music: NotchMedia.player?.isPlaying ?? false
                    tracking: NotchSettings.values.mascotTracking && root.cursorMoving
                    running: visible && root.visible
                    opacity: root.mascotShown && !root.expanded && !root.osdShown && !root.alertShown ? 1 : 0
                    visible: opacity > 0

                    onWoke: {
                        root.mascotShown = false;
                        root.visiting = false;
                        if (hoverHandler.hovered)
                            root.hovered = true;
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Item {
                    id: expandedView

                    anchors.fill: parent
                    anchors.margins: pill.padding
                    opacity: root.expanded ? 1 : 0
                    visible: opacity > 0
                    focus: root.expanded

                    Keys.onLeftPressed: root.step(-1)
                    Keys.onRightPressed: root.step(1)
                    Keys.onEscapePressed: {
                        root.screenState.notch = false;
                        root.hovered = false;
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Loader {
                        id: pageLoader

                        anchors.top: header.bottom
                        anchors.topMargin: Tokens.spacing.medium
                        anchors.horizontalCenter: parent.horizontalCenter
                        active: root.expanded || expandedView.visible
                        sourceComponent: root.pageComponents[root.page.id] ?? placeholderPage
                    }

                    Item {
                        id: header

                        readonly property real minWidth: Math.max(title.implicitWidth, stamp.implicitWidth) * 2 + dots.implicitWidth + Tokens.spacing.large * 2

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        implicitHeight: Math.max(dots.implicitHeight, title.implicitHeight, stamp.implicitHeight)

                        StyledText {
                            id: title

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.page.label
                            color: Hallownest.soul
                            font.family: Hallownest.serif
                            font.pointSize: 12
                            font.weight: Font.Bold
                            font.letterSpacing: 0.6
                            animate: true
                        }

                        CharmNotches {
                            id: dots

                            anchors.centerIn: parent
                            current: root.pageIndex
                            notches: NotchPages.pages

                            onSelected: index => root.goTo(index)
                            onStepped: delta => root.step(delta)
                        }

                        Row {
                            id: stamp

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Tokens.spacing.small

                            StyledText {
                                anchors.baseline: time.baseline
                                text: Qt.locale().toString(clock.date, "ddd d MMM yyyy")
                                color: Hallownest.subtext
                                font.pointSize: 9
                            }

                            StyledText {
                                id: time

                                text: Qt.locale().toString(clock.date, NotchSettings.twelveHour ? "h:mm AP" : "HH:mm")
                                color: Hallownest.soul
                                font.family: Hallownest.mono
                                font.pointSize: 11
                                font.weight: Font.Bold
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: island

        readonly property real gap: 10
        readonly property real bodyWidth: root.expanded ? 300 : Math.min(420, islandLine.implicitWidth + Tokens.padding.large * 2)

        x: container.x + (shape.leftFillet + pill.width + gap - islandShape.leftFillet) * NotchSettings.scale
        y: Config.border.thickness
        implicitWidth: islandShape.width * NotchSettings.scale
        implicitHeight: islandShape.height * NotchSettings.scale
        opacity: root.islandShown ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    leaveTimer.stop();
                else if (root.expanded)
                    leaveTimer.restart();
            }
        }

        Item {
            width: islandShape.width
            height: islandShape.height
            scale: NotchSettings.scale
            transformOrigin: Item.TopLeft

            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 32
                    shadowBlur: 1
                    shadowVerticalOffset: 3
                    shadowColor: root.glowColour
                }

                IslandShape {
                    id: islandShape

                    w: island.bodyWidth
                    h: pill.height
                    radius: pill.radius
                    leftFillet: 4

                    Behavior on w {
                        Anim {
                            type: Anim.DefaultSpatial
                        }
                    }
                }
            }

            Item {
                x: islandShape.leftFillet
                width: islandShape.w
                height: islandShape.h
                clip: true

                Item {
                    anchors.fill: parent
                    opacity: root.expanded ? 0 : 1
                    visible: opacity > 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    StyledText {
                        id: islandLine

                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, 420 - Tokens.padding.large * 2)
                        text: NotchMedia.currentLine || "♪"
                        color: Hallownest.soul
                        font.pointSize: 10
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        animate: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.screenState.notchPage = NotchPages.pages.findIndex(p => p.id === "media");
                            root.screenState.notch = true;
                        }
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: root.expanded && !Lyrics.hasLyrics
                    text: Lyrics.loading ? Tr.tr("Searching lyrics…") : Tr.tr("No lyrics found")
                    color: Hallownest.subtext
                    font.family: Hallownest.serif
                    font.pointSize: 10
                }

                ListView {
                    id: lyricList

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: pill.padding
                    height: Math.min(parent.height - pill.padding * 2, 120)
                    visible: root.expanded && Lyrics.hasLyrics
                    opacity: root.expanded ? 1 : 0
                    clip: true
                    interactive: false
                    model: Lyrics.lyrics
                    spacing: Tokens.spacing.medium
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    highlightMoveDuration: Tokens.anim.durations.large
                    highlightMoveVelocity: -1
                    preferredHighlightBegin: height / 2 - 12
                    preferredHighlightEnd: height / 2 + 12

                    Component.onCompleted: {
                        currentIndex = Qt.binding(() => {
                            model;
                            return NotchMedia.lyricIndex;
                        });
                        positionViewAtIndex(currentIndex, ListView.Center);
                    }
                    onModelChanged: Qt.callLater(() => positionViewAtIndex(currentIndex, ListView.Center))
                    onVisibleChanged: {
                        if (visible)
                            Qt.callLater(() => positionViewAtIndex(currentIndex, ListView.Center));
                    }

                    highlight: Item {
                        Shape {
                            anchors.centerIn: parent
                            width: lyricList.width * 1.1
                            height: 46
                            preferredRendererType: Shape.CurveRenderer

                            ShapePath {
                                strokeWidth: -1
                                fillGradient: RadialGradient {
                                    centerX: lyricList.width * 0.55
                                    centerY: 23
                                    centerRadius: lyricList.width * 0.5
                                    focalX: centerX
                                    focalY: centerY

                                    GradientStop {
                                        position: 0
                                        color: Qt.alpha(Hallownest.crystal, 0.13)
                                    }
                                    GradientStop {
                                        position: 1
                                        color: "transparent"
                                    }
                                }

                                PathRectangle {
                                    width: lyricList.width * 1.1
                                    height: 46
                                }
                            }
                        }
                    }

                    delegate: StyledText {
                        id: line

                        required property string modelData
                        required property int index
                        readonly property bool current: ListView.isCurrentItem

                        width: lyricList.width
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData || "♪"
                        color: Qt.alpha(Hallownest.soul, current ? 1 : lineMouse.containsMouse ? 0.6 : 0.35)
                        font.pointSize: current ? 11 : 10
                        font.weight: current ? Font.Bold : Font.Normal
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight

                        Behavior on color {
                            CAnim {}
                        }

                        MouseArea {
                            id: lineMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotchMedia.seekToLine(line.index)
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }
    }

    Component {
        id: placeholderPage

        Pages.Placeholder {
            screenState: root.screenState
            page: root.page
        }
    }

    Component {
        id: mediaPage

        Pages.Media {
            screenState: root.screenState
            page: root.page
        }
    }

    Component {
        id: calendarPage

        Pages.Calendar {
            screenState: root.screenState
            page: root.page
        }
    }

    Component {
        id: weatherPage

        Pages.Weather {
            screenState: root.screenState
            page: root.page
        }
    }

    Component {
        id: settingsPage

        Pages.Settings {
            screenState: root.screenState
            page: root.page
        }
    }

    Component {
        id: performancePage

        Pages.Performance {
            screenState: root.screenState
            page: root.page
        }
    }

    Component {
        id: aiPage

        Pages.Ai {
            screenState: root.screenState
            page: root.page
        }
    }

    Component {
        id: shelfPage

        Pages.Shelf {
            screenState: root.screenState
            page: root.page
        }
    }

    Component {
        id: pomodoroPage

        Pages.Pomodoro {
            screenState: root.screenState
            page: root.page
        }
    }

    Component {
        id: todoPage

        Pages.Todo {
            screenState: root.screenState
            page: root.page
        }
    }
}
