import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.services

Item {
    id: root

    property real size: 20
    property bool filled: true
    property color colour: Hallownest.soul
    property color eyeColour: Hallownest.void_
    property bool glow

    implicitWidth: size
    implicitHeight: size

    Item {
        width: 90
        height: 74
        anchors.centerIn: parent
        scale: root.size / 90
        layer.enabled: root.glow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.colour
            shadowOpacity: 0.7
            shadowBlur: 0.8
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 24
        }

        Shape {
            x: -100
            y: -32
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.filled ? root.colour : Qt.alpha(root.colour, 0.3)
                strokeWidth: -1

                PathSvg {
                    path: "M 116.73,80.86 C 107.51,75.66 105.00,61.82 108.35,53.16 C 110.86,46.24 115.89,40.18 120.42,36.37 L 121.59,40.70 L 126.95,41.39 C 119.24,44.51 113.38,49.70 112.87,56.62 C 112.54,60.95 115.05,63.55 119.24,65.28 L 119.24,59.22 L 169.52,59.22 L 169.52,65.28 C 173.71,63.55 176.23,60.95 175.89,56.62 C 175.39,49.70 169.52,44.51 161.81,41.39 L 167.18,40.70 L 168.35,36.37 C 172.87,40.18 177.90,46.24 180.42,53.16 C 183.77,61.82 181.25,75.66 172.04,80.86 L 172.88,88.82 Q 172.88,101.62 160.08,101.62 L 128.69,101.62 Q 115.89,101.62 115.89,88.82 Z"
                }
            }

            ShapePath {
                fillColor: root.filled ? root.eyeColour : "transparent"
                strokeWidth: -1

                PathSvg {
                    path: "M 138.84,77 A 8.54 10.92 0 1 1 121.76,77 A 8.54 10.92 0 1 1 138.84,77 Z M 167.04,77 A 8.54 10.92 0 1 1 149.96,77 A 8.54 10.92 0 1 1 167.04,77 Z"
                }
            }
        }
    }
}
