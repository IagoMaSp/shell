pragma Singleton

import Quickshell
import Caelestia.I18n

Singleton {
    readonly property var pages: [
        {
            id: "media",
            icon: "music_note",
            label: Tr.tr("Media")
        },
        {
            id: "calendar",
            icon: "calendar_month",
            label: Tr.tr("Calendar")
        },
        {
            id: "weather",
            icon: "partly_cloudy_day",
            label: Tr.tr("Weather")
        },
        {
            id: "performance",
            icon: "speed",
            label: Tr.tr("Performance")
        },
        {
            id: "ai",
            icon: "smart_toy",
            label: Tr.tr("AI")
        },
        {
            id: "shelf",
            icon: "inventory_2",
            label: Tr.tr("Shelf")
        },
        {
            id: "pomodoro",
            icon: "timer",
            label: Tr.tr("Focus")
        },
        {
            id: "todo",
            icon: "checklist",
            label: Tr.tr("To-Do")
        },
        {
            id: "settings",
            icon: "settings",
            label: Tr.tr("Settings")
        }
    ]
}
