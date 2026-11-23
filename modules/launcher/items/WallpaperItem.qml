import QtQuick
import Caelestia.Config
import Caelestia.Models
import Caelestia.Multimedia
import qs.components
import qs.components.effects
import qs.services

Item {
    id: root

    required property FileSystemEntry modelData
    required property ScreenState screenState
    property real imageWidth: Tokens.sizes.launcher.wallpaperWidth

    // qmllint disable missing-property
    scale: PathView.onPath ? PathView.itemScale ?? 1 : 0
    opacity: PathView.onPath ? PathView.itemOpacity ?? 1 : 0
    z: PathView.z ?? 0
    // qmllint enable missing-property

    implicitWidth: image.width + Tokens.padding.medium * 2
    implicitHeight: image.height + label.height + Tokens.spacing.extraSmall + Tokens.padding.large + Tokens.padding.medium

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: {
            Wallpapers.setWallpaper(root.modelData.path);
            root.screenState.launcher = false;
        }
    }

    Elevation {
        anchors.fill: image
        radius: image.radius
        opacity: root.PathView.isCurrentItem ? 1 : 0
        level: 4

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    ClipRect {
        id: image

        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.padding.large
        color: Hallownest.card
        radius: Tokens.rounding.large

        implicitWidth: root.imageWidth
        implicitHeight: implicitWidth / 16 * 9

        MaterialIcon {
            anchors.centerIn: parent
            text: "image"
            color: Hallownest.steel
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.DemiBold).build()
        }

        Visual {
            anchors.fill: parent
            source: root.modelData.path
            playing: root.PathView.isCurrentItem
        }

        Rectangle {
            anchors.fill: parent
            radius: image.radius
            color: "transparent"
            border.width: 1
            border.color: root.PathView.isCurrentItem ? Qt.alpha(Hallownest.soul, 0.5) : Hallownest.border
        }
    }

    StyledText {
        id: label

        anchors.top: image.bottom
        anchors.topMargin: Tokens.spacing.extraSmall
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Tokens.padding.medium * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
        text: root.modelData.relativePath
        color: root.PathView.isCurrentItem ? Hallownest.soul : Hallownest.subtext
        font: Tokens.font.label.medium
    }
}
