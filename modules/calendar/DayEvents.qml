pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

Item {
    id: root

    required property date date
    readonly property list<var> events: Events.eventsOn(date)
    property bool adding
    property string editingUid

    signal close

    function formatDate(date: date): string {
        return Qt.formatDate(date, Events.dateFormat);
    }

    onDateChanged: {
        adding = false;
        editingUid = "";
        Events.loadMonth(date.getFullYear(), date.getMonth(), "window");
    }

    Component.onCompleted: Events.loadMonth(date.getFullYear(), date.getMonth(), "window")

    Keys.onEscapePressed: {
        if (adding || editingUid) {
            adding = false;
            editingUid = "";
        } else {
            close();
        }
    }

    ColumnLayout {
        id: header

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.extraLarge
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: Qt.locale().toString(root.date, "dddd")
                    color: Colours.palette.m3primary
                    font: Tokens.font.title.builders.small.capitalisation(Font.Capitalize).build()
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Qt.locale().toString(root.date, "d MMMM yyyy")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.headline.medium
                    elide: Text.ElideRight
                }
            }

            IconButton {
                isRound: true
                type: IconButton.Text
                icon: "close"
                onClicked: root.close()
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: !Events.available
            text: Tr.tr("khal is not installed or configured, so events can't be loaded")
            color: Colours.palette.m3error
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }
    }

    StyledFlickable {
        id: view

        anchors.top: header.bottom
        anchors.bottom: footer.visible ? footer.top : parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.extraLarge
        anchors.topMargin: Tokens.spacing.large
        anchors.bottomMargin: Tokens.spacing.large

        clip: true
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: content.implicitHeight

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: view
        }

        ColumnLayout {
            id: content

            width: view.width
            spacing: Tokens.spacing.small

            Repeater {
                model: root.events

                Loader {
                    id: eventLoader

                    required property var modelData

                    Layout.fillWidth: true
                    sourceComponent: root.editingUid === modelData.uid ? editForm : eventCard

                    Component {
                        id: eventCard

                        EventCard {
                            modelData: eventLoader.modelData
                        }
                    }

                    Component {
                        id: editForm

                        EventForm {
                            event: eventLoader.modelData
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.large
                visible: root.events.length === 0 && !root.adding
                horizontalAlignment: Text.AlignHCenter
                text: Tr.tr("No events this day")
                color: Colours.palette.m3outline
                font: Tokens.font.body.medium
            }

            Loader {
                Layout.fillWidth: true
                Layout.topMargin: root.events.length > 0 ? Tokens.spacing.large : 0
                active: root.adding
                visible: active

                sourceComponent: EventForm {}
            }
        }
    }

    RowLayout {
        id: footer

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.extraLarge
        visible: !root.adding && !root.editingUid

        Item {
            Layout.fillWidth: true
        }

        IconTextButton {
            disabled: !Events.available
            icon: "add"
            text: Tr.tr("Add event")
            onClicked: {
                root.editingUid = "";
                root.adding = true;
            }
        }
    }

    component EventCard: StyledRect {
        id: card

        required property var modelData
        property bool confirmDelete

        Layout.fillWidth: true
        implicitHeight: cardLayout.implicitHeight + Tokens.padding.large * 2

        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer

        RowLayout {
            id: cardLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            StyledRect {
                Layout.fillHeight: true
                implicitWidth: 4
                radius: 2
                color: card.modelData.colour || Colours.palette.m3primary
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.fillWidth: true
                    text: card.modelData.allDay ? Tr.tr("All day") : `${card.modelData.start} – ${card.modelData.end}`
                    color: Colours.palette.m3primary
                    font: Tokens.font.label.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: card.modelData.title
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.small
                    wrapMode: Text.WordWrap
                }

                InfoRow {
                    icon: "location_on"
                    text: card.modelData.location
                }

                InfoRow {
                    icon: "event_repeat"
                    text: card.modelData.recurring ? (card.modelData.until ? Tr.tr("Weekly until %1").arg(root.formatDate(card.modelData.until)) : Tr.tr("Repeats")) : ""
                }

                InfoRow {
                    icon: "notes"
                    text: card.modelData.description
                }
            }

            IconButton {
                Layout.alignment: Qt.AlignTop
                isRound: true
                type: IconButton.Text
                icon: "edit"
                disabled: !!root.editingUid || root.adding
                onClicked: root.editingUid = card.modelData.uid
            }

            IconButton {
                Layout.alignment: Qt.AlignTop
                isRound: true
                type: card.confirmDelete ? IconButton.Filled : IconButton.Text
                icon: card.confirmDelete ? "delete_forever" : "delete"
                activeColour: Colours.palette.m3error
                inactiveColour: card.confirmDelete ? Colours.palette.m3error : Colours.palette.m3surfaceContainer
                inactiveOnColour: card.confirmDelete ? Colours.palette.m3onError : Colours.palette.m3onSurfaceVariant
                onClicked: {
                    if (card.confirmDelete)
                        Events.remove(card.modelData.uid);
                    else
                        card.confirmDelete = true;
                }
            }
        }

        // Reset the delete confirmation if not confirmed shortly
        Timer {
            running: card.confirmDelete
            interval: 3000
            onTriggered: card.confirmDelete = false
        }
    }

    component InfoRow: RowLayout {
        id: info

        property string icon
        property string text

        Layout.fillWidth: true
        visible: !!text
        spacing: Tokens.spacing.extraSmall

        MaterialIcon {
            Layout.alignment: Qt.AlignTop
            text: info.icon
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            Layout.fillWidth: true
            text: info.text
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }
    }

    component EventForm: ColumnLayout {
        id: form

        // Event being edited (null when adding). Edits to a repeating event apply to the whole series.
        property var event: null
        readonly property bool editingSeries: !!event?.recurring
        readonly property string initialUntil: event?.until ? root.formatDate(event.until) : ""

        readonly property var timeRe: /^([01]?\d|2[0-3]):[0-5]\d$/
        readonly property date eventDate: dateField.visible ? Date.fromLocaleDateString(Qt.locale(), dateField.text.trim(), Events.dateFormat) : root.date
        readonly property bool dateValid: !dateField.visible || !isNaN(eventDate)
        readonly property date untilDate: Date.fromLocaleDateString(Qt.locale(), untilField.text.trim(), Events.dateFormat)
        readonly property bool untilValid: !weekly.checked || !untilField.text.trim() || (!isNaN(untilDate) && (editingSeries || untilDate >= eventDate))
        readonly property bool timesValid: allDay.checked || (timeRe.test(startField.text) && timeRe.test(endField.text) && endField.text.padStart(5, "0") > startField.text.padStart(5, "0"))
        readonly property bool valid: titleField.text.trim() && timesValid && untilValid && dateValid

        function close(): void {
            root.adding = false;
            root.editingUid = "";
        }

        function save(): void {
            if (!valid)
                return;

            const data = {
                title: titleField.text.trim(),
                // A series keeps its start day, unless it stops repeating (then it stays on this day)
                date: editingSeries && weekly.checked ? null : eventDate,
                allDay: allDay.checked,
                start: startField.text.padStart(5, "0"),
                end: endField.text.padStart(5, "0"),
                weekly: weekly.checked,
                until: weekly.checked && untilField.text.trim() ? untilDate : null,
                untilChanged: untilField.text.trim() !== initialUntil,
                location: locationField.text.trim(),
                description: descriptionField.text.trim()
            };
            if (event)
                Events.update(event.uid, data);
            else
                Events.add(data);
            close();
        }

        spacing: Tokens.spacing.medium

        Component.onCompleted: titleField.forceActiveFocus()

        StyledText {
            text: form.event ? Tr.tr("Edit event") : Tr.tr("New event")
            color: Colours.palette.m3onSurface
            font: Tokens.font.title.medium
        }

        StyledTextField {
            id: titleField

            Layout.fillWidth: true
            placeholderText: Tr.tr("Title")
            leadingIcon: "title"
            text: form.event?.title ?? ""
            onAccepted: form.save()
        }

        StyledTextField {
            id: dateField

            Layout.fillWidth: true
            visible: !!form.event && !form.editingSeries
            placeholderText: Tr.tr("Date")
            leadingIcon: "event"
            text: root.formatDate(root.date)
            errorText: Tr.tr("Enter a valid date")
            isError: !form.dateValid
            onAccepted: form.save()
        }

        StyledText {
            Layout.fillWidth: true
            visible: form.editingSeries
            text: Tr.tr("Changes apply to every occurrence")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        SwitchRow {
            id: allDay

            label: Tr.tr("All day")
            checked: form.event?.allDay ?? false
        }

        RowLayout {
            Layout.fillWidth: true
            visible: !allDay.checked
            spacing: Tokens.spacing.medium

            StyledTextField {
                id: startField

                Layout.fillWidth: true
                placeholderText: Tr.tr("Start")
                leadingIcon: "schedule"
                text: form.event && !form.event.allDay ? form.event.start : "09:00"
                validate: form.timeRe
                isError: !valid
                onAccepted: form.save()
            }

            StyledTextField {
                id: endField

                Layout.fillWidth: true
                placeholderText: Tr.tr("End")
                leadingIcon: "schedule"
                text: form.event && !form.event.allDay ? form.event.end : "10:00"
                validate: form.timeRe
                isError: !valid || (startField.valid && !form.timesValid)
                errorText: startField.valid && !form.timesValid ? Tr.tr("Must be after start") : ""
                onAccepted: form.save()
            }
        }

        SwitchRow {
            id: weekly

            label: form.event?.recurring && !/FREQ=WEEKLY/.test(form.event.repeat ?? "") ? Tr.tr("Repeat") : Tr.tr("Repeat weekly")
            checked: form.event?.recurring ?? false
        }

        StyledTextField {
            id: untilField

            Layout.fillWidth: true
            visible: weekly.checked
            placeholderText: Tr.tr("Until (optional)")
            leadingIcon: "event_busy"
            text: form.initialUntil
            supportingText: {
                const count = /COUNT=(\d+)/.exec(form.event?.repeat ?? "");
                if (count && !text.trim())
                    return Tr.tr("Currently ends after %1 occurrences").arg(count[1]);
                return Tr.tr("Last day, e.g. %1").arg(root.formatDate(new Date(root.date.getFullYear(), root.date.getMonth() + 1, root.date.getDate())));
            }
            errorText: Tr.tr("Enter a date after this day")
            isError: !form.untilValid
            onAccepted: form.save()
        }

        StyledTextField {
            id: locationField

            Layout.fillWidth: true
            placeholderText: Tr.tr("Location (optional)")
            leadingIcon: "location_on"
            text: form.event?.location ?? ""
            onAccepted: form.save()
        }

        StyledTextField {
            id: descriptionField

            Layout.fillWidth: true
            placeholderText: Tr.tr("Notes (optional)")
            leadingIcon: "notes"
            text: form.event?.description ?? ""
            onAccepted: form.save()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            spacing: Tokens.spacing.small

            Item {
                Layout.fillWidth: true
            }

            TextButton {
                isRound: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                type: TextButton.Tonal
                text: Tr.trCtx("Cancel", "button")
                onClicked: form.close()
            }

            TextButton {
                isRound: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: !form.valid
                text: Tr.trCtx("Save", "button")
                onClicked: form.save()
            }
        }
    }

    component SwitchRow: RowLayout {
        id: switchRow

        property alias label: switchLabel.text
        property alias checked: toggle.checked

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        StyledText {
            id: switchLabel

            Layout.fillWidth: true
            color: Colours.palette.m3onSurface
            font: Tokens.font.body.medium
        }

        StyledSwitch {
            id: toggle
        }
    }
}
