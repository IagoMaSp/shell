pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    // [{path, name, dir, isDir}], best matches first
    property var results: []
    property string query

    function search(text: string): void {
        query = text.trim().toLowerCase();
        debounce.restart();
    }

    function run(): void {
        if (proc.running)
            return; // Relaunched in onExited
        const words = query.split(/\s+/).filter(w => w);
        if (!words.length) {
            results = [];
            return;
        }
        proc.query = query;
        proc.words = words;
        // fd matches one fixed string; the other words are filtered on the name below
        const longest = words.reduce((a, b) => b.length > a.length ? b : a);
        proc.command = ["fd", "--ignore-case", "--no-ignore-vcs", "--fixed-strings", "--max-results", "3000", "-E", "node_modules", "-E", "__pycache__", "-E", "site-packages", "-E", "venv", "-E", "target", "-E", "CMakeFiles", "--", longest, home];
        proc.running = true;
    }

    function parse(text: string, words: var): var {
        const first = words[0];
        const out = [];
        for (const line of text.split("\n")) {
            if (!line)
                continue;
            const isDir = line.endsWith("/");
            const path = isDir ? line.slice(0, -1) : line;
            const cut = path.lastIndexOf("/");
            const name = path.slice(cut + 1);
            const lower = name.toLowerCase();
            if (!words.every(w => lower.includes(w)))
                continue;
            out.push({
                path: path,
                name: name,
                dir: path.slice(0, cut),
                isDir: isDir,
                score: (lower.startsWith(first) ? 0 : 1000) + path.length
            });
        }
        return out.sort((a, b) => a.score - b.score).slice(0, 30);
    }

    function open(path: string): void {
        Quickshell.execDetached(["xdg-open", path]);
    }

    function iconFor(item: var): string {
        if (item.isDir)
            return "folder";
        const ext = item.name.includes(".") ? item.name.split(".").pop().toLowerCase() : "";
        const groups = {
            "application-pdf": ["pdf"],
            "image-x-generic": ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "avif", "heic"],
            "audio-x-generic": ["mp3", "flac", "ogg", "oga", "wav", "m4a", "opus"],
            "video-x-generic": ["mp4", "mkv", "webm", "mov", "avi"],
            "x-office-document": ["doc", "docx", "odt", "rtf"],
            "x-office-spreadsheet": ["xls", "xlsx", "ods", "csv"],
            "x-office-presentation": ["ppt", "pptx", "odp"],
            "package-x-generic": ["zip", "tar", "gz", "xz", "zst", "7z", "rar"],
            "text-x-script": ["py", "js", "ts", "qml", "lua", "sh", "fish", "c", "cpp", "h", "hpp", "rs", "java", "go"]
        };
        for (const icon in groups)
            if (groups[icon].includes(ext))
                return icon;
        return "text-x-generic";
    }

    Timer {
        id: debounce

        interval: 120
        onTriggered: root.run()
    }

    Process {
        id: proc

        property string query
        property var words: []

        stdout: StdioCollector {
            onStreamFinished: {
                if (proc.query === root.query)
                    root.results = root.parse(text, proc.words);
            }
        }

        onExited: {
            if (proc.query !== root.query)
                root.run();
        }
    }
}
