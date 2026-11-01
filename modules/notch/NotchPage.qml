import QtQuick
import qs.components

Item {
    property ScreenState screenState
    property var page

    opacity: 0

    Component.onCompleted: opacity = 1

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
