pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Widgets
import qs.services

// Animated Hallownest backdrop for the current weather:
// sun = Greenpath, night = lumaflies, cloud = drifting mist, fog = Fog Canyon,
// rain/storm = City of Tears, snow = Crystal Peak
ClippingRectangle {
    id: root

    property string kind
    property bool night
    property bool running: visible
    property real t

    readonly property string shownKind: Weather.previewScene === "night" ? "sun" : Weather.previewScene || kind
    readonly property bool shownNight: Weather.previewScene ? Weather.previewScene === "night" : night
    readonly property string scene: {
        if (shownKind === "rain" || shownKind === "storm")
            return "tears";
        if (shownKind === "snow")
            return "crystal";
        if (shownKind === "fog")
            return "fog";
        if (shownNight)
            return "night";
        if (shownKind === "sun" || shownKind === "twilight" || shownKind === "partly")
            return "greenpath";
        return "cloud";
    }
    readonly property var colours: ({
            greenpath: ["#16301f", "#0b1510", "#c9e07a"],
            night: ["#0d1426", "#06070a", "#d9f27a"],
            cloud: ["#1b2230", "#0b0d12", "#9aa6b8"],
            fog: ["#2c1a33", "#100a14", "#f0a6d8"],
            tears: ["#0f2238", "#06090f", "#6cc9ff"],
            crystal: ["#2a1530", "#0c070f", "#f4b6e6"]
        })[scene]
    readonly property color accent: colours[2]
    readonly property real flash: shownKind === "storm" && ((t * 9) % 1 < 0.03 || ((t * 9) % 1 > 0.06 && (t * 9) % 1 < 0.08)) ? 1 : 0

    // Deterministic pseudo-random in [0, 1) so silhouettes don't change between frames
    function rand(i: int): real {
        const x = Math.sin(i * 12.9898 + 78.233) * 43758.5453;
        return x - Math.floor(x);
    }

    function phase(seed: real, speed: real): real {
        return (t * speed + seed) % 1;
    }

    // City of Tears skyline (towers with spires) in a 600x60 box
    function skyline(): string {
        let d = "M 0 60";
        let x = 0;
        for (let i = 0; x < 600; i++) {
            const w = 18 + rand(i) * 26;
            const h = 18 + rand(i + 40) * 30;
            d += ` L ${x} ${60 - h} L ${x + w * 0.3} ${60 - h} L ${x + w * 0.5} ${60 - h - 8 - rand(i + 80) * 10} L ${x + w * 0.7} ${60 - h} L ${x + w} ${60 - h}`;
            x += w + rand(i + 120) * 8;
            d += ` L ${x} ${60 - h * 0.4}`;
        }
        return d + " L 600 60 Z";
    }

    // Crystal Peak shards in a 600x60 box
    function shards(): string {
        let d = "";
        let x = -10;
        for (let i = 0; x < 610; i++) {
            const w = 10 + rand(i + 7) * 22;
            const h = 14 + rand(i + 31) * 44;
            const lean = (rand(i + 59) - 0.5) * 12;
            d += `M ${x} 60 L ${x + w / 2 + lean} ${60 - h} L ${x + w} 60 Z `;
            x += w * 0.6 + rand(i + 97) * 10;
        }
        return d;
    }

    visible: NotchSettings.values.animWeather
    radius: 16
    color: colours[1]
    border.width: 1
    border.color: Hallownest.border

    NumberAnimation on t {
        running: root.running
        loops: Animation.Infinite
        from: 0
        to: 1
        duration: 60000
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.colours[0]
            }
            GradientStop {
                position: 1
                color: root.colours[1]
            }
        }
    }

    // Greenpath: slow light rays
    Repeater {
        model: root.scene === "greenpath" ? 4 : 0

        Rectangle {
            required property int index

            x: root.width * (0.15 + index * 0.22)
            y: -root.height * 0.3
            width: 26 + index * 6
            height: root.height * 1.6
            rotation: 24
            opacity: 0.08 + 0.06 * Math.sin((root.t * 20 + index * 0.37) * Math.PI * 2)
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: root.accent
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
        }
    }

    // Mist bands (cloud, fog), blurred together
    Item {
        anchors.fill: parent
        visible: root.scene === "cloud" || root.scene === "fog"
        layer.enabled: visible
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1
            blurMax: 48
        }

        Repeater {
            model: 5

            Rectangle {
                required property int index
                readonly property real p: root.phase(root.rand(index + 200), 3 + index)

                x: -width + p * (root.width + width * 2)
                y: root.height * (0.15 + index * 0.17)
                width: root.width * (0.35 + root.rand(index + 210) * 0.3)
                height: 18 + root.rand(index + 220) * 16
                radius: height / 2
                color: Qt.alpha(root.accent, root.scene === "fog" ? 0.24 : 0.22)
            }
        }
    }

    // Fog Canyon: bobbing uoma
    Repeater {
        model: root.scene === "fog" ? 5 : 0

        Rectangle {
            required property int index
            readonly property real seed: root.rand(index + 300)

            x: root.width * (0.08 + index * 0.2) + Math.sin((root.t * 6 + seed) * Math.PI * 2) * 10
            y: root.height * (0.25 + seed * 0.5) + Math.sin((root.t * 14 + seed) * Math.PI * 2) * 8
            width: 10 + seed * 10
            height: width
            radius: width / 2
            color: Qt.alpha(root.accent, 0.12)
            border.width: 1
            border.color: Qt.alpha(root.accent, 0.5)

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.35
                height: width
                radius: width / 2
                color: Qt.alpha(root.accent, 0.6)
            }
        }
    }

    // Night: twinkling diamond stars and wandering lumaflies
    Repeater {
        model: root.scene === "night" ? 22 : 0

        Rectangle {
            required property int index

            x: root.rand(index + 400) * root.width
            y: root.rand(index + 430) * root.height * 0.75
            width: 2 + root.rand(index + 460) * 2.5
            height: width
            rotation: 45
            color: Hallownest.soul
            opacity: 0.25 + 0.55 * Math.abs(Math.sin((root.t * (8 + index % 5) + root.rand(index + 490)) * Math.PI * 2))
        }
    }

    Repeater {
        model: root.scene === "night" || root.scene === "greenpath" ? 7 : 0

        Rectangle {
            required property int index
            readonly property real seed: root.rand(index + 500)

            x: root.width * (0.1 + seed * 0.8) + Math.sin((root.t * 5 + seed) * Math.PI * 2) * 40
            y: root.height * (0.3 + root.rand(index + 520) * 0.6) + Math.cos((root.t * 7 + seed) * Math.PI * 2) * 12
            width: 3
            height: 3
            radius: 1.5
            color: root.colours[2]
            opacity: root.scene === "night" ? 0.5 + 0.5 * Math.sin((root.t * 30 + seed) * Math.PI * 2) : 0.35

            Rectangle {
                anchors.centerIn: parent
                width: 12
                height: 12
                radius: 6
                color: Qt.alpha(root.colours[2], 0.18)
            }
        }
    }

    // Greenpath: falling leaves
    Repeater {
        model: root.scene === "greenpath" ? 7 : 0

        Shape {
            id: leaf

            required property int index
            readonly property real seed: root.rand(index + 600)
            readonly property real p: root.phase(seed, 6 + seed * 4)

            x: -20 + p * (root.width + 40) + Math.sin((p * 3 + seed) * Math.PI * 2) * 14
            y: -12 + p * (root.height + 24)
            rotation: p * 720 * (seed > 0.5 ? 1 : -1)
            opacity: 0.75
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Qt.alpha(leaf.seed > 0.6 ? "#d8c66a" : "#7fbf6a", 0.8)
                strokeWidth: -1

                PathSvg {
                    path: "M 0 0 Q 6 -4.5 12 0 Q 6 4.5 0 0 Z"
                }
            }
        }
    }

    // City of Tears / Crystal Peak silhouettes along the bottom
    Shape {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 60
        visible: root.scene === "tears" || root.scene === "crystal"
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            xScale: root.width / 600
        }

        ShapePath {
            fillColor: root.scene === "tears" ? "#132c44" : Qt.alpha(root.accent, 0.22)
            strokeColor: Qt.alpha(root.accent, root.scene === "crystal" ? 0.5 : 0.35)
            strokeWidth: 0.8

            PathSvg {
                path: root.scene === "tears" ? root.skyline() : root.scene === "crystal" ? root.shards() : ""
            }
        }
    }

    // City of Tears: lit windows
    Repeater {
        model: root.scene === "tears" ? 10 : 0

        Rectangle {
            required property int index

            x: root.rand(index + 700) * root.width
            y: root.height - 8 - root.rand(index + 720) * 22
            width: 2
            height: 3
            color: Hallownest.lifeblood
            opacity: 0.35 + 0.35 * Math.sin((root.t * 4 + root.rand(index + 740)) * Math.PI * 2)
        }
    }

    // Rain streaks
    Repeater {
        model: root.scene === "tears" ? 40 : 0

        Rectangle {
            required property int index
            readonly property real seed: root.rand(index + 800)
            readonly property real p: root.phase(seed, 70 + seed * 40)

            x: seed * (root.width + 40) - 20 - p * 18
            y: -14 + p * (root.height + 20)
            width: 1
            height: 9 + seed * 6
            rotation: 12
            color: Qt.alpha(Hallownest.lifeblood, 0.35 + seed * 0.3)
        }
    }

    // Snow diamonds
    Repeater {
        model: root.scene === "crystal" ? 28 : 0

        Rectangle {
            required property int index
            readonly property real seed: root.rand(index + 900)
            readonly property real p: root.phase(seed, 10 + seed * 8)

            x: seed * root.width + Math.sin((p * 2 + seed) * Math.PI * 2) * 10
            y: -6 + p * (root.height + 12)
            width: 2.5 + seed * 2
            height: width
            rotation: 45
            color: Hallownest.soul
            opacity: 0.8
        }
    }

    // Lightning
    Rectangle {
        anchors.fill: parent
        color: Hallownest.soul
        opacity: root.flash * 0.25
        visible: opacity > 0
    }

    // Keep the text side readable
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Qt.alpha(Hallownest.void_, 0.55)
            }
            GradientStop {
                position: 0.55
                color: Qt.alpha(Hallownest.void_, 0.1)
            }
            GradientStop {
                position: 1
                color: Qt.alpha(Hallownest.void_, 0.45)
            }
        }
    }
}
