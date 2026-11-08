pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// The Knight resting on a bench (the user's drawing, split by scripts/hallownest-bench.py).
// Coordinates are those of the 320x220 SVG canvas; `canvasScale` sizes it.
Item {
    id: root

    property real canvasScale: 1
    property real breath
    property real lookX
    property real lookY
    property real raise // head lifted towards the password, 0..1
    property real blink
    property real shake
    property real stand // 0 = sitting, 1 = standing up
    property bool typing
    property bool following

    // Look up at the password field for a moment
    function look(): void {
        typing = true;
        lookX = 0;
        lookY = -5;
        raise = 1;
        lookReset.restart();
    }

    // Eyes follow a point given in this item's coordinates
    function follow(x: real, y: real): void {
        if (typing || stand > 0)
            return;
        const dx = x / canvasScale - 160;
        const dy = y / canvasScale - 99;
        const d = Math.max(Math.hypot(dx, dy), 1);
        const reach = Math.min(d / 60, 1);
        lookX = dx / d * 4 * reach;
        lookY = dy / d * 3.5 * reach;
        following = true;
        followReset.restart();
    }

    function refuse(): void {
        refuseAnim.restart();
    }

    function standUp(): void {
        refuseAnim.stop();
        typing = false;
        lookX = 0;
        lookY = 0;
        raise = 0;
        standAnim.restart();
    }

    implicitWidth: 320 * canvasScale
    implicitHeight: 220 * canvasScale

    SequentialAnimation on breath {
        loops: Animation.Infinite

        NumberAnimation {
            to: 1
            duration: 2200
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 0
            duration: 2600
            easing.type: Easing.InOutSine
        }
    }

    Behavior on lookX {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuad
        }
    }

    Behavior on lookY {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuad
        }
    }

    Behavior on raise {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: lookReset

        interval: 2500
        onTriggered: {
            root.typing = false;
            root.raise = 0;
            root.lookY = 0;
        }
    }

    Timer {
        id: followReset

        interval: 2000
        onTriggered: {
            root.following = false;
            if (!root.typing) {
                root.lookX = 0;
                root.lookY = 0;
            }
        }
    }

    // Idle glances to the sides
    Timer {
        running: root.visible && !root.typing && !root.following && root.stand === 0
        interval: 3500
        repeat: true
        onTriggered: {
            interval = 2500 + Math.random() * 4000;
            root.lookX = Math.random() < 0.5 ? 0 : (Math.random() < 0.5 ? -2 : 2);
        }
    }

    Timer {
        running: root.visible && root.stand === 0
        interval: 4000
        repeat: true
        onTriggered: {
            interval = 2500 + Math.random() * 4000;
            blinkAnim.restart();
        }
    }

    SequentialAnimation {
        id: blinkAnim

        NumberAnimation {
            target: root
            property: "blink"
            to: 1
            duration: 70
        }
        NumberAnimation {
            target: root
            property: "blink"
            to: 0
            duration: 110
        }
    }

    // "No": shake the head slowly
    SequentialAnimation {
        id: refuseAnim

        NumberAnimation {
            target: root
            property: "shake"
            to: -1
            duration: 260
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: 1
            duration: 480
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: -0.7
            duration: 440
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: 0
            duration: 340
            easing.type: Easing.InOutSine
        }
    }

    // Gets up from the bench: crouch, then rise until the legs clear the seat
    SequentialAnimation {
        id: standAnim

        NumberAnimation {
            target: root
            property: "stand"
            to: -0.12
            duration: 120
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "stand"
            to: 1
            duration: 380
            easing.type: Easing.OutCubic
        }
    }

    Item {
        width: 320
        height: 220
        scale: root.canvasScale
        transformOrigin: Item.TopLeft

        BenchLayer {
            name: "banco"
        }

        Item {
            anchors.fill: parent
            transform: Translate {
                y: -root.stand * 22
            }

            BenchLayer {
                name: "cuerpo"
                transform: Scale {
                    origin.x: 160
                    origin.y: 150
                    yScale: 1 + root.breath * 0.025 + Math.max(root.stand, 0) * 0.06
                }
            }

            // Head and eyes ride on top of the breathing body and turn around the neck
            Item {
                anchors.fill: parent
                transform: [
                    Rotation {
                        origin.x: 160
                        origin.y: 112
                        angle: root.shake * 6
                    },
                    Translate {
                        y: -root.breath * 0.9 - root.raise * 4 - Math.max(root.stand, 0) * 2
                    }
                ]

                BenchLayer {
                    name: "cabeza"
                }

                BenchLayer {
                    name: "ojos"
                    transform: [
                        Scale {
                            origin.y: 99
                            yScale: 1 - root.blink * 0.9
                        },
                        Translate {
                            x: root.lookX
                            y: root.lookY
                        }
                    ]
                }
            }
        }
    }

    component BenchLayer: Image {
        required property string name

        width: 320
        height: 220
        source: Quickshell.shellPath(`assets/hallownest/bench/${name}.png`)
        sourceSize: Qt.size(1280, 880)
        smooth: true
        mipmap: true
    }
}
