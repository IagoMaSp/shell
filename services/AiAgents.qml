pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.utils

// Quick access to AI coding agents (Claude Code, Antigravity): launches them in a terminal or their
// desktop app and lists recent sessions. Lives outside the dashboard so the folder picker survives
// the dashboard closing.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    readonly property var providers: [
        {
            id: "claude",
            name: "Claude Code",
            bin: "claude",
            appBin: "claude-desktop",
            icon: "claude-desktop",
            fallbackIcon: "smart_toy",
            promptArgs: [],
            continueArgs: ["--continue"],
            resumeArgs: ["--resume"]
        },
        {
            id: "antigravity",
            name: "Antigravity",
            bin: "agy",
            appBin: "antigravity",
            icon: "antigravity",
            fallbackIcon: "rocket_launch",
            promptArgs: ["-i"],
            continueArgs: ["-c"],
            resumeArgs: ["--conversation"]
        }
    ]

    property string providerId: "claude"
    readonly property var provider: providers.find(p => p.id === providerId) ?? providers[0]

    // Resolved executable paths by name (empty if not installed) and CLI versions by provider id
    property var paths: ({})
    property var versions: ({})

    readonly property bool hasCli: !!paths[provider.bin]
    readonly property bool hasApp: !!paths[provider.appBin]

    property var sessions: []
    property string directory: home
    property bool loading

    // Unique working directories of recent sessions (skipping worktrees), home first
    readonly property var directories: {
        const dirs = [home];
        for (const s of sessions)
            if (dirs.length < 6 && !dirs.includes(s.cwd) && !s.cwd.includes("/.claude/worktrees/"))
                dirs.push(s.cwd);
        if (!dirs.includes(directory))
            dirs.push(directory);
        return dirs;
    }

    function setProvider(id: string): void {
        if (id === providerId)
            return;
        providerId = id;
        sessions = [];
        providerFile.setText(id);
        reload();
    }

    function reload(): void {
        if (sessionsProc.running) {
            sessionsProc.pending = true;
            return;
        }
        loading = true;
        sessionsProc.command = ["python3", Quickshell.shellPath("assets/ai-sessions.py"), providerId, "8"];
        sessionsProc.running = true;
    }

    function prettyPath(path: string): string {
        if (path === home)
            return "~";
        return path.startsWith(home + "/") ? "~" + path.slice(home.length) : path;
    }

    function dirName(path: string): string {
        return path === home ? "~" : path.slice(path.lastIndexOf("/") + 1);
    }

    function openTerminal(args: var, dir: string): void {
        if (!hasCli)
            return;
        // execDetached's object form (with workingDirectory) is rejected by this Quickshell, so cd via sh
        Quickshell.execDetached(["sh", "-c", 'cd "$1" && shift && exec "$@"', "sh", dir || directory, ...GlobalConfig.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, paths[provider.bin], ...(args ?? [])]);
    }

    function newSession(): void {
        openTerminal([]);
    }

    function continueSession(): void {
        openTerminal(provider.continueArgs);
    }

    function ask(prompt: string): void {
        const text = prompt.trim();
        if (text)
            openTerminal([...provider.promptArgs, text]);
    }

    function resume(session: var): void {
        openTerminal([...provider.resumeArgs, session.id], session.cwd);
    }

    function openApp(): void {
        if (!hasApp)
            return;
        if (provider.id === "claude")
            Quickshell.execDetached([paths[provider.appBin], "claude://code/new?source=desktop_action"]);
        else
            Quickshell.execDetached([paths[provider.appBin], directory]);
    }

    function pickDirectory(): void {
        if (!picker.running)
            picker.running = true;
    }

    Component.onCompleted: detectProc.running = true

    FileView {
        id: providerFile

        path: `${Paths.state}/ai-provider`
        printErrors: false
        onLoaded: {
            const id = text().trim();
            if (root.providers.some(p => p.id === id) && id !== root.providerId) {
                root.providerId = id;
                root.sessions = [];
                root.reload();
            }
        }
    }

    Process {
        id: detectProc

        // ~/.local/bin isn't always in the shell's PATH (agy installs there)
        command: ["sh", "-c", 'PATH="$PATH:$HOME/.local/bin"; for b in "$@"; do printf "%s=%s\\n" "$b" "$(command -v "$b")"; done', "sh", ...root.providers.reduce((acc, p) => acc.concat([p.bin, p.appBin]), [])]
        stdout: StdioCollector {
            onStreamFinished: {
                const paths = {};
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        paths[line.slice(0, i)] = line.slice(i + 1);
                }
                root.paths = paths;
                versionProc.running = true;
                root.reload();
            }
        }
    }

    Process {
        id: versionProc

        command: ["sh", "-c", 'while [ $# -gt 0 ]; do [ -n "$2" ] && printf "%s=%s\\n" "$1" "$("$2" --version 2>/dev/null | head -1)"; shift 2; done', "sh", ...root.providers.reduce((acc, p) => acc.concat([p.id, root.paths[p.bin] ?? ""]), [])]
        stdout: StdioCollector {
            onStreamFinished: {
                const versions = {};
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf("=");
                    const match = /\d+(\.\d+)+/.exec(line.slice(i + 1));
                    if (i > 0 && match)
                        versions[line.slice(0, i)] = match[0];
                }
                root.versions = versions;
            }
        }
    }

    Process {
        id: sessionsProc

        property bool pending

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.sessions = JSON.parse(text);
                } catch (e) {
                    root.sessions = [];
                }
            }
        }
        onExited: {
            root.loading = false;
            if (pending) {
                pending = false;
                root.reload();
            }
        }
    }

    Process {
        id: picker

        command: ["zenity", "--file-selection", "--directory", `--title=${Tr.tr("Working directory")}`, `--filename=${root.directory}/`]
        stdout: StdioCollector {
            id: pickerOut
        }
        onExited: code => {
            const dir = pickerOut.text.trim();
            if (code === 0 && dir)
                root.directory = dir;
        }
    }
}
