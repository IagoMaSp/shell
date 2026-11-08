import QtQuick
import SddmComponents 2.0

// PaleShell login screen: void black, Cinzel clock, soul diamonds for the password
Rectangle {
    id: root

    readonly property color void_: "#06070a"
    readonly property color card: "#14161c"
    readonly property color soul: config.accent || "#f0f4f8"
    readonly property color steel: config.steel || "#9ba4b5"
    readonly property color text_: "#e2e8f0"
    readonly property color subtext: "#8a93a3"
    readonly property color grimm: "#e63946"

    property int userIndex: Math.max(0, users.names.indexOf(userModel.lastUser))
    property int sessionIndex: sessionModel.lastIndex
    property bool failed

    function login(): void {
        failed = false;
        sddm.login(users.names[userIndex] ?? userModel.lastUser, password.text, sessionIndex);
    }

    width: 1920
    height: 1080
    color: void_

    Component.onCompleted: password.forceActiveFocus()

    Connections {
        function onLoginFailed() {
            root.failed = true;
            password.text = "";
            shake.restart();
        }

        target: sddm
    }

    FontLoader {
        id: cinzel

        source: "Cinzel.ttf"
    }

    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.alpha(root.void_, 0.55)
            }
            GradientStop {
                position: 0.6
                color: Qt.alpha(root.void_, 0.8)
            }
            GradientStop {
                position: 1
                color: Qt.alpha(root.void_, 0.95)
            }
        }
    }

    // Hidden model readers
    Repeater {
        id: users

        property var names: []

        model: userModel
        delegate: Item {
            required property string name

            Component.onCompleted: users.names = users.names.concat([name])
        }
    }

    Repeater {
        id: sessions

        property var names: []

        model: sessionModel
        delegate: Item {
            required property int index
            required property string name

            Component.onCompleted: {
                const n = sessions.names.slice();
                n[index] = name;
                sessions.names = n;
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date();
            hours.text = Qt.formatTime(now, "HH");
            minutes.text = Qt.formatTime(now, "mm");
            date.text = Qt.locale().toString(now, "dddd, d MMMM");
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.14
        spacing: 6

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 18

            Text {
                id: hours

                color: root.soul
                font.family: cinzel.name
                font.pixelSize: 128
                font.weight: Font.Bold
                style: Text.Raised
                styleColor: Qt.alpha(root.soul, 0.25)
            }

            Text {
                anchors.verticalCenter: hours.verticalCenter
                text: "◆"
                color: root.steel
                font.pixelSize: 26
            }

            Text {
                id: minutes

                color: root.steel
                font.family: cinzel.name
                font.pixelSize: 128
                font.weight: Font.Bold
            }
        }

        Text {
            id: date

            anchors.horizontalCenter: parent.horizontalCenter
            color: root.subtext
            font.family: cinzel.name
            font.pixelSize: 22
            font.capitalization: Font.Capitalize
            font.letterSpacing: 1.5
        }
    }

    Column {
        id: form

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.verticalCenter
        anchors.topMargin: 40
        spacing: 18

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: users.names.length > 1
                text: "‹"
                color: root.subtext
                font.pixelSize: 30

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.userIndex = (root.userIndex - 1 + users.names.length) % users.names.length
                }
            }

            Text {
                text: users.names[root.userIndex] ?? userModel.lastUser
                color: root.text_
                font.family: cinzel.name
                font.pixelSize: 26
                font.weight: Font.Bold
                font.letterSpacing: 2
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: users.names.length > 1
                text: "›"
                color: root.subtext
                font.pixelSize: 30

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.userIndex = (root.userIndex + 1) % users.names.length
                }
            }
        }

        Item {
            id: field

            anchors.horizontalCenter: parent.horizontalCenter
            width: 360
            height: 52

            SequentialAnimation {
                id: shake

                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -14; duration: 50 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 12; duration: 70 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -8; duration: 70 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
            }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Qt.alpha(root.card, 0.85)
                border.width: 1
                border.color: root.failed ? root.grimm : password.activeFocus ? Qt.alpha(root.soul, 0.7) : Qt.alpha(root.steel, 0.3)

                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: password.text.length === 0
                text: root.failed ? "Incorrect password" : "Password"
                color: root.failed ? root.grimm : root.subtext
                font.family: cinzel.name
                font.pixelSize: 15
                font.letterSpacing: 1
            }

            TextInput {
                id: password

                anchors.fill: parent
                anchors.leftMargin: 26
                anchors.rightMargin: 60
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "◆"
                color: root.soul
                font.pixelSize: 16
                font.letterSpacing: 4
                selectionColor: Qt.alpha(root.soul, 0.3)
                focus: true
                clip: true

                Keys.onReturnPressed: root.login()
                Keys.onEnterPressed: root.login()
                onTextChanged: {
                    if (text.length)
                        root.failed = false;
                }
            }

            // Submit button in a diamond
            Item {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30

                Rectangle {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    rotation: 45
                    radius: 3
                    color: submitMouse.containsMouse ? root.soul : "transparent"
                    border.width: 1.5
                    border.color: root.soul
                }

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    color: submitMouse.containsMouse ? root.void_ : root.soul
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: submitMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.login()
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: keyboard.capsLock
            text: "Caps Lock is on"
            color: "#f4a261"
            font.pixelSize: 13
        }
    }

    // Session selector
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 32
        width: sessionLabel.implicitWidth + 44
        height: 38
        radius: height / 2
        color: sessionMouse.containsMouse ? Qt.alpha(root.soul, 0.08) : Qt.alpha(root.card, 0.8)
        border.width: 1
        border.color: Qt.alpha(root.steel, 0.3)

        Text {
            id: sessionLabel

            anchors.centerIn: parent
            text: "◇  " + (sessions.names[root.sessionIndex] ?? "Session")
            color: root.text_
            font.pixelSize: 14
        }

        MouseArea {
            id: sessionMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, sessionModel.rowCount())
        }
    }

    // Power buttons
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32
        spacing: 14

        PowerButton {
            label: "Sleep"
            colour: "#38bdf8"
            visible: sddm.canSuspend
            onActivated: sddm.suspend()
        }

        PowerButton {
            label: "Reboot"
            colour: "#f4a261"
            visible: sddm.canReboot
            onActivated: sddm.reboot()
        }

        PowerButton {
            label: "Shutdown"
            colour: root.grimm
            visible: sddm.canPowerOff
            onActivated: sddm.powerOff()
        }
    }

    component PowerButton: Rectangle {
        id: btn

        property string label
        property color colour

        signal activated

        width: btnLabel.implicitWidth + 36
        height: 38
        radius: height / 2
        color: btnMouse.containsMouse ? Qt.alpha(colour, 0.15) : Qt.alpha(root.card, 0.8)
        border.width: 1
        border.color: btnMouse.containsMouse ? colour : Qt.alpha(root.steel, 0.3)

        Text {
            id: btnLabel

            anchors.centerIn: parent
            text: btn.label
            color: btnMouse.containsMouse ? btn.colour : root.text_
            font.family: cinzel.name
            font.pixelSize: 13
            font.weight: Font.Bold
            font.letterSpacing: 1
        }

        MouseArea {
            id: btnMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.activated()
        }
    }
}
