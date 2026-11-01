pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string browser: "zen-browser"
    readonly property string browserName: "Zen Browser"
    readonly property string engineName: "Google"
    readonly property string engineUrl: "https://www.google.com/search?q="
    // Site engines from the browser profile: [{name, aliases, url}], url contains {searchTerms}
    property var engines: []

    function reload(): void {
        enginesProc.running = true;
    }

    function isUrl(text: string): bool {
        const t = text.trim();
        return /^https?:\/\/\S+$/i.test(t) || /^(localhost|([\w-]+\.)+[a-z]{2,})(:\d+)?(\/\S*)?$/i.test(t);
    }

    // Matches "@yt cats" or "@youtube cats" (also just "@yt") to a site engine
    function siteSearch(text: string): var {
        const match = /^(\S+)(?:\s+([\s\S]*))?$/.exec(text.trim());
        if (!match)
            return null;
        const keyword = match[1].toLowerCase();
        for (const engine of root.engines) {
            const names = engine.aliases.map(a => a.toLowerCase());
            names.push(`@${engine.name.toLowerCase().replace(/\s+/g, "")}`);
            if (names.includes(keyword))
                return {
                    engine: engine,
                    query: match[2] ?? ""
                };
        }
        return null;
    }

    function urlFor(text: string): string {
        const t = text.trim();
        const site = siteSearch(t);
        if (site)
            return site.engine.url.replace("{searchTerms}", encodeURIComponent(site.query.trim()));
        if (isUrl(t))
            return /^https?:\/\//i.test(t) ? t : `${t.startsWith("localhost") ? "http" : "https"}://${t}`;
        return root.engineUrl + encodeURIComponent(t);
    }

    // Opens a new tab in the running browser, or starts it if it isn't open
    function open(text: string): void {
        const site = siteSearch(text);
        if (site ? site.query.trim() : text.trim())
            Quickshell.execDetached([root.browser, "--new-tab", urlFor(text)]);
    }

    Component.onCompleted: reload()

    Process {
        id: enginesProc

        command: ["python3", Quickshell.shellPath("assets/zen-engines.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.engines = JSON.parse(text);
                } catch (e) {
                    root.engines = [];
                }
            }
        }
    }
}
