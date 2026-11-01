import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool session
    property bool launcher
    property bool notch
    property bool utilities
    property bool sidebar

    property int notchPage
    property int mascotCalls
    property date calendarDate: new Date()
}
