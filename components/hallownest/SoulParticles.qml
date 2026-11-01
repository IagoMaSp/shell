pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root

    property int count: 6
    property color colour: Hallownest.soul
    property bool running
    property real size: 2
    property real rise: height
    property int duration: 2800

    Repeater {
        model: root.running || root.visible ? root.count : 0

        Rectangle {
            id: particle

            required property int index
            readonly property real seed: Math.random()
            property real t

            x: seed * (root.width - width) + Math.sin(t * 6.28 + seed * 10) * 2
            y: root.height - height - t * root.rise
            width: root.size * (0.6 + seed * 0.8)
            height: width
            radius: width / 2
            color: root.colour
            opacity: Math.sin(t * Math.PI) * 0.85

            NumberAnimation on t {
                running: root.running
                loops: Animation.Infinite
                from: 0
                to: 1
                duration: root.duration * (0.7 + particle.seed * 0.9)
            }
        }
    }
}
