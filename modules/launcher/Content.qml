pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property ScreenState screenState
    required property var panels
    required property real maxHeight

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge
    // The dock's app menu shows its own grid until something is typed
    readonly property alias query: search.text
    property bool listShown: true
    // Grid shown instead of the list while nothing is typed (the dock's app menu)
    property GridView appGrid
    readonly property real searchHeight: search.height + padding + search.anchors.bottomMargin

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: searchHeight + (listShown ? listWrapper.height : 0)

    Item {
        id: listWrapper

        visible: root.listShown
        implicitWidth: list.width
        implicitHeight: list.height + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: search.top
        anchors.bottomMargin: root.padding

        ContentList {
            id: list

            content: root
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight - search.implicitHeight - root.padding * 3
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }

    SearchBar {
        id: search

        objectName: "launcherSearch"

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding
        anchors.bottomMargin: CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding)

        topPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)
        bottomPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)

        placeholderText: Tr.tr("Type \"%1\" for commands").arg(GlobalConfig.launcher.actionPrefix)

        onAccepted: {
            if (!root.listShown && root.appGrid) {
                root.appGrid.currentItem?.launch();
                return;
            }
            const currentItem = list.currentList?.currentItem;
            if (currentItem) {
                if (list.showWallpapers) {
                    if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                        Wallpapers.previewColourLock = true;
                    Wallpapers.setWallpaper(currentItem.modelData.path);
                    root.screenState.launcher = false;
                } else if (["calc", "web", "files", "tr"].includes(list.currentList.state)) {
                    currentItem.onClicked();
                } else if (text.startsWith(GlobalConfig.launcher.actionPrefix)) {
                    currentItem.modelData.onClicked(list.currentList);
                } else {
                    currentItem.open();
                }
            }
        }

        Keys.onUpPressed: !root.listShown && root.appGrid ? root.appGrid.moveCurrentIndexUp() : list.currentList?.decrementCurrentIndex()
        Keys.onDownPressed: !root.listShown && root.appGrid ? root.appGrid.moveCurrentIndexDown() : list.currentList?.incrementCurrentIndex()
        Keys.onLeftPressed: event => {
            if (!root.listShown && root.appGrid)
                root.appGrid.moveCurrentIndexLeft();
            else
                event.accepted = false;
        }
        Keys.onRightPressed: event => {
            if (!root.listShown && root.appGrid)
                root.appGrid.moveCurrentIndexRight();
            else
                event.accepted = false;
        }

        Keys.onEscapePressed: root.screenState.launcher = false

        Keys.onPressed: event => {
            // Shift+Enter always searches the web, even if an app matches
            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ShiftModifier) && !list.showWallpapers) {
                // ...except in file search, where it opens the containing folder
                if (list.currentList?.state === "files") {
                    list.currentList.currentItem?.openFolder();
                    event.accepted = true;
                    return;
                }
                const prefix = GlobalConfig.launcher.actionPrefix;
                const webPrefix = `${prefix}web `;
                const query = text.startsWith(webPrefix) ? text.slice(webPrefix.length) : (text.startsWith(prefix) ? "" : text);
                if (query.trim()) {
                    WebSearch.open(query);
                    root.screenState.launcher = false;
                    event.accepted = true;
                    return;
                }
            }

            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab) {
                list.currentList?.incrementCurrentIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                list.currentList?.decrementCurrentIndex();
                event.accepted = true;
            }
        }

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher)
                    search.text = "";
            }

            function onSessionChanged(): void {
                if (!root.screenState.session)
                    search.forceActiveFocus();
            }

            target: root.screenState
        }
    }
}
