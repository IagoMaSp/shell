pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentScheme: `Hollow Knight ${Hallownest.flavour}`

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}theme `.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.flavour}`;
    }

    list: schemes.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes
    keys: ["flavour", "name"]
    weights: [0.9, 0.1]

    Variants {
        id: schemes

        model: Hallownest.flavours

        Scheme {}
    }

    component Scheme: QtObject {
        required property string modelData
        readonly property string name: "Hollow Knight"
        readonly property string flavour: modelData
        readonly property var colours: ({
                surface: Hallownest.void_.toString().slice(1),
                outline: Hallownest.steels[modelData].slice(1),
                primary: Hallownest.accents[modelData].slice(1)
            })

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            Hallownest.setFlavour(flavour);
        }
    }
}
