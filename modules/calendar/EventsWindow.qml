pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// Floating window listing the events of a single day, opened from the dashboard calendar
Singleton {
    id: root

    property date date: new Date()

    function open(date: date): void {
        root.date = date;
        loader.activeAsync = true;
    }

    function close(): void {
        loader.active = false;
    }

    LazyLoader {
        id: loader

        FloatingWindow {
            id: win

            implicitWidth: 440
            implicitHeight: 620
            minimumSize.width: 360
            minimumSize.height: 400

            color: Colours.tPalette.m3surface
            surfaceFormat.opaque: false
            title: Tr.tr("Events — %1").arg(Qt.locale().toString(root.date, "d MMMM yyyy"))

            contentItem.Config.screen: screen?.name ?? ""
            contentItem.Tokens.screen: screen?.name ?? ""

            onVisibleChanged: {
                if (!visible)
                    root.close();
            }

            DayEvents {
                anchors.fill: parent
                date: root.date
                onClose: root.close()
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
