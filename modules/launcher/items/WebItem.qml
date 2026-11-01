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

        spacing: Tokens.spacing.medium

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            text: root.isUrl ? "language" : "travel_explore"
            color: Colours.palette.m3onSurfaceVariant
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
                color: root.searchText ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.isUrl ? WebSearch.browserName : Tr.tr("%1 in %2").arg(root.site?.engine.name ?? WebSearch.engineName).arg(WebSearch.browserName)
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            text: "open_in_new"
            color: Colours.palette.m3outline
            fontStyle: Tokens.font.icon.large
        }
    }
}
