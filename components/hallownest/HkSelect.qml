pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property var options: []
    property int currentIndex: -1
    readonly property string currentText: label(options[currentIndex])
    property string placeholder

    signal activated(index: int)

    function label(option: var): string {
        if (option === undefined || option === null)
            return "";
        return typeof option === "object" ? option.text ?? "" : String(option);
    }

    implicitWidth: Math.max(140, field.implicitWidth)
    implicitHeight: 30

    HkButton {
        id: field

        anchors.fill: parent
        text: root.currentText || root.placeholder
        icon: popup.opened ? "expand_less" : "expand_more"
        iconAfter: true
        onClicked: popup.opened ? popup.close() : popup.open()
    }

    Popup {
        id: popup

        y: root.height + 4
        width: Math.max(root.width, 160)
        padding: 4

        background: HkCard {
            radius: 12
        }

        contentItem: ListView {
            id: list

            implicitHeight: Math.min(contentHeight, 240)
            clip: true
            model: root.options

            delegate: Rectangle {
                id: option

                required property var modelData
                required property int index

                width: list.width
                implicitHeight: 28
                radius: 8
                color: optionArea.containsMouse ? Hallownest.button : "transparent"

                StyledText {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.label(option.modelData)
                    color: option.index === root.currentIndex ? Hallownest.soul : Hallownest.text
                    font.pointSize: 10
                    font.weight: option.index === root.currentIndex ? Font.Bold : Font.Normal
                }

                MaterialIcon {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    visible: option.index === root.currentIndex
                    text: "check"
                    color: Hallownest.lifeblood
                    fontStyle: Tokens.font.icon.small
                }

                MouseArea {
                    id: optionArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.activated(option.index);
                        popup.close();
                    }
                }
            }
        }
    }
}
