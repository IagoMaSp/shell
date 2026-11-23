import QtQuick
import qs.components
import qs.services

Row {
    id: root

    property real value
    property real from: 0
    property real to: 99
    property real stepSize: 1
    property int decimals: stepSize < 1 ? 2 : 0
    property string suffix

    signal moved(value: real)

    function step(dir: int): void {
        const next = Math.round((value + dir * stepSize) / stepSize) * stepSize;
        moved(Math.max(from, Math.min(to, Number(next.toFixed(decimals)))));
    }

    spacing: 8

    HkButton {
        implicitHeight: 24
        icon: "remove"
        disabled: root.value <= root.from
        onClicked: root.step(-1)
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(44, implicitWidth)
        horizontalAlignment: Text.AlignHCenter
        text: root.value.toFixed(root.decimals) + root.suffix
        color: Hallownest.soul
        font.family: Hallownest.mono
        font.pointSize: 10
        font.weight: Font.Bold
    }

    HkButton {
        implicitHeight: 24
        icon: "add"
        disabled: root.value >= root.to
        onClicked: root.step(1)
    }
}
