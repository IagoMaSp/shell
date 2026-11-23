pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Caelestia.Services
import qs.components.hallownest
import qs.services

Item {
    id: root

    property bool running
    property color colour: Hallownest.glowBlue
    readonly property var values: Audio.cava.values

    function level(i: int): real {
        const n = values?.length ?? 0;
        if (!running || n === 0)
            return 0.2;
        const group = Math.max(1, Math.floor(n / 4));
        let sum = 0;
        for (let j = i * group; j < Math.min(n, (i + 1) * group); j++)
            sum += values[j];
        return Math.min(1, sum / group * 1.6);
    }

    implicitWidth: bars.implicitWidth
    implicitHeight: 14

    Loader {
        active: root.running

        sourceComponent: ServiceRef {
            service: Audio.cava
        }
    }

    SoulParticles {
        anchors.fill: parent
        anchors.topMargin: -12
        anchors.leftMargin: -3
        anchors.rightMargin: -3
        count: 4
        size: 2
        colour: Qt.alpha(Hallownest.soul, 0.8)
        running: root.running
        duration: 3400
    }

    Row {
        id: bars

        height: parent.height
        spacing: 2.5
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.colour
            shadowBlur: 0.6
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 10
        }

        Repeater {
            model: 4

            Rectangle {
                required property int index

                y: bars.height - height
                width: 3
                height: Math.max(3, root.level(index) * bars.height)
                radius: 1.5
                color: root.colour

                Behavior on height {
                    NumberAnimation {
                        duration: 90
                    }
                }
            }
        }
    }
}
