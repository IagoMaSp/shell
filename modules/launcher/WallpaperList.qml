pragma ComponentBehavior: Bound

import "items"
import QtQuick
import Quickshell
import qs.components.controls
import qs.services

PathView {
    id: root

    required property SearchBar search
    required property var screenState

    // Coverflow across the dock's app menu: the current wallpaper large in the middle, its
    // neighbours smaller and faded at the sides
    readonly property real imageWidth: Math.min(width * 0.64, (height - 40) / 9 * 16)

    model: ScriptModel {
        id: scriptModel

        readonly property string search: root.search.text.split(" ").slice(1).join(" ")

        values: Wallpapers.query(search)
        onValuesChanged: root.currentIndex = search ? 0 : values.findIndex(w => w.path === Wallpapers.actualCurrent)
    }

    Component.onCompleted: currentIndex = Wallpapers.list.findIndex(w => w.path === Wallpapers.actualCurrent)
    Component.onDestruction: Wallpapers.stopPreview()

    onCurrentItemChanged: {
        if (currentItem)
            Wallpapers.preview((currentItem as WallpaperItem).modelData.path);
    }

    pathItemCount: Math.min(3, count)
    cacheItemCount: 4

    snapMode: PathView.SnapToItem
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    delegate: WallpaperItem {
        screenState: root.screenState
        imageWidth: root.imageWidth
    }

    path: Path {
        startX: 0
        startY: root.height / 2

        PathAttribute {
            name: "z"
            value: 0
        }
        PathAttribute {
            name: "itemScale"
            value: 0.3
        }
        PathAttribute {
            name: "itemOpacity"
            value: 0.25
        }
        PathLine {
            x: root.width / 2
            relativeY: 0
        }
        PathAttribute {
            name: "z"
            value: 1
        }
        PathAttribute {
            name: "itemScale"
            value: 1
        }
        PathAttribute {
            name: "itemOpacity"
            value: 1
        }
        PathLine {
            x: root.width
            relativeY: 0
        }
        PathAttribute {
            name: "z"
            value: 0
        }
        PathAttribute {
            name: "itemScale"
            value: 0.3
        }
        PathAttribute {
            name: "itemOpacity"
            value: 0.25
        }
    }

    CustomMouseArea {
        function onWheel(event: WheelEvent): void {
            if (event.angleDelta.y > 0)
                root.decrementCurrentIndex();
            else if (event.angleDelta.y < 0)
                root.incrementCurrentIndex();
        }

        anchors.fill: parent
    }
}
