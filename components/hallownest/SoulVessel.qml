import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Widgets
import qs.components
import qs.services

Item {
    id: root

    property real level
    property color colour: Hallownest.soul
    property bool running
    property real phase
    property real shown: Math.max(0, Math.min(1, level))

    function wave(offset: real, amp: real): string {
        const w = width;
        const h = height;
        const y0 = h * (1 - shown);
        let d = `M 0 ${y0 + Math.sin(phase + offset) * amp}`;
        for (let i = 1; i <= 16; i++) {
            const x = w * i / 16;
            d += ` L ${x} ${y0 + Math.sin(phase + offset + i / 16 * Math.PI * 2) * amp}`;
        }
        return d + ` L ${w} ${h} L 0 ${h} Z`;
    }

    implicitWidth: 112
    implicitHeight: 112

    Behavior on shown {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    NumberAnimation on phase {
        running: root.running && root.visible
        loops: Animation.Infinite
        from: 0
        to: Math.PI * 2
        duration: 2600
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Hallownest.steel, 0.25)
    }

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.colour
            shadowOpacity: 0.5
            shadowBlur: 1
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 20
        }

        ClippingRectangle {
            anchors.fill: parent
            radius: width / 2
            color: Hallownest.card
            border.width: 2
            border.color: Qt.alpha(Hallownest.steel, 0.45)

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Qt.alpha(root.colour, 0.35)
                    strokeWidth: -1

                    PathSvg {
                        path: root.wave(Math.PI, 3)
                    }
                }

                ShapePath {
                    fillColor: root.colour
                    strokeWidth: -1

                    PathSvg {
                        path: root.wave(0, 2.5)
                    }
                }
            }
        }
    }
}
