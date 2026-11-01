pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.hallownest
import qs.services

Item {
    id: root

    required property PopoutState popouts

    implicitWidth: Tokens.sizes.bar.audioWidth
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.medium

        StyledText {
            text: Tr.trCtx("Output device", "audio output device")
            color: Hallownest.steel
            font.family: Hallownest.serif
            font.pointSize: 10
            font.weight: Font.Bold
        }

        Repeater {
            model: Audio.sinks

            HkRadio {
                required property PwNode modelData

                Layout.fillWidth: true
                checked: Audio.sink?.id === modelData.id
                onClicked: Audio.setAudioSink(modelData)
                text: modelData.description
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            text: Tr.trCtx("Input device", "audio input device")
            color: Hallownest.steel
            font.family: Hallownest.serif
            font.pointSize: 10
            font.weight: Font.Bold
        }

        Repeater {
            model: Audio.sources

            HkRadio {
                required property PwNode modelData

                Layout.fillWidth: true
                checked: Audio.source?.id === modelData.id
                onClicked: Audio.setAudioSource(modelData)
                text: modelData.description
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            text: Audio.muted ? Tr.tr("Volume (muted)") : Tr.tr("Volume (%1%)").arg(Math.round(Audio.volume * 100))
            color: Hallownest.steel
            font.family: Hallownest.serif
            font.pointSize: 10
            font.weight: Font.Bold
        }

        CustomMouseArea {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.medium * 3

            onWheel: event => {
                if (event.angleDelta.y > 0)
                    Audio.incrementVolume();
                else if (event.angleDelta.y < 0)
                    Audio.decrementVolume();
            }

            HkSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                colour: Hallownest.lifeblood
                value: Audio.volume
                onMoved: value => Audio.setVolume(value)
            }
        }

        HkButton {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.medium
            text: Tr.tr("Open settings")
            icon: "settings"
            tinted: true
            accent: Hallownest.lifeblood

            onClicked: root.popouts.detachRequested("audio")
        }
    }
}
