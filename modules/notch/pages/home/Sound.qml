pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services
import qs.utils

RowLayout {
    id: root

    spacing: Tokens.spacing.medium

    Channel {
        title: Tr.trCtx("Output", "audio output device")
        icon: Icons.getVolumeIcon(Audio.volume, Audio.muted)
        node: Audio.sink
        nodes: Audio.sinks
        muted: Audio.muted
        volume: Audio.volume
        onSetVolume: v => Audio.setVolume(v)
        onSelect: n => Audio.setAudioSink(n)
        onStep: up => up ? Audio.incrementVolume() : Audio.decrementVolume()
    }

    Channel {
        title: Tr.trCtx("Input", "audio input device")
        icon: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
        node: Audio.source
        nodes: Audio.sources
        muted: Audio.sourceMuted
        volume: Audio.sourceVolume
        onSetVolume: v => Audio.setSourceVolume(v)
        onSelect: n => Audio.setAudioSource(n)
        onStep: up => up ? Audio.incrementSourceVolume() : Audio.decrementSourceVolume()
    }

    component Channel: HkCard {
        id: channel

        property string title
        property string icon
        property PwNode node
        property var nodes
        property bool muted
        property real volume

        signal setVolume(v: real)
        signal select(n: PwNode)
        signal step(up: bool)

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        implicitHeight: column.implicitHeight + 28

        ColumnLayout {
            id: column

            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    Layout.fillWidth: true
                    text: channel.title
                    color: Hallownest.steel
                    font.family: Hallownest.serif
                    font.pointSize: 10
                    font.weight: Font.Bold
                }

                StyledText {
                    text: channel.muted ? Tr.tr("Muted") : `${Math.round(channel.volume * 100)}%`
                    color: channel.muted ? Hallownest.grimm : Hallownest.soul
                    font.family: Hallownest.serif
                    font.pointSize: 11
                    font.weight: Font.Bold
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                HkButton {
                    icon: channel.icon
                    accent: channel.muted ? Hallownest.grimm : Hallownest.soul
                    tinted: channel.muted
                    onClicked: {
                        if (channel.node?.audio)
                            channel.node.audio.muted = !channel.muted;
                    }
                }

                MouseArea {
                    Layout.fillWidth: true
                    implicitHeight: 24
                    acceptedButtons: Qt.NoButton
                    onWheel: e => channel.step(e.angleDelta.y > 0)

                    HkSlider {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        value: channel.volume
                        colour: channel.muted ? Hallownest.faint : Hallownest.lifeblood
                        onMoved: v => channel.setVolume(v)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 2
                implicitHeight: 1
                color: Hallownest.border
            }

            Repeater {
                model: channel.nodes

                HkRadio {
                    required property PwNode modelData

                    Layout.fillWidth: true
                    checked: channel.node?.id === modelData.id
                    accent: Hallownest.lifeblood
                    text: modelData.description
                    onClicked: channel.select(modelData)
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
