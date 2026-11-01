import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property var list
    readonly property string query: list.webQuery.trim()
    readonly property var site: WebSearch.siteSearch(query)
    readonly property string searchText: site ? site.query.trim() : query
    readonly property bool isUrl: !site && WebSearch.isUrl(query)

    function onClicked(): void {
        if (!searchText)
            return;
        WebSearch.open(query);
        root.list.screenState.launcher = false;
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.onClicked()
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.medium + 16
        anchors.rightMargin: Tokens.padding.medium + 16

        spacing: Tokens.spacing.medium

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            text: root.isUrl ? "language" : "travel_explore"
            color: Hallownest.subtext
            fontStyle: Tokens.font.icon.extraLarge
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: {
                    if (!root.searchText)
                        return root.site ? Tr.tr("Type something to search %1").arg(root.site.engine.name) : Tr.tr("Type something to search the web");
                    return root.isUrl ? Tr.tr("Open %1").arg(root.query) : Tr.tr("Search \"%1\"").arg(root.searchText);
                }
                color: root.searchText ? Hallownest.soul : Hallownest.subtext
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.isUrl ? WebSearch.browserName : Tr.tr("%1 in %2").arg(root.site?.engine.name ?? WebSearch.engineName).arg(WebSearch.browserName)
                color: Hallownest.faint
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            text: "open_in_new"
            color: Hallownest.faint
            fontStyle: Tokens.font.icon.large
        }
    }
}
