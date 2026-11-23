pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
import qs.utils

// Live Claude Code sessions, fed by assets/agent-hook.py over a Unix socket. Permission requests
// and AskUserQuestion prompts wait on their connection until they are answered from the notch.
Singleton {
    id: root

    readonly property string socketPath: `${Quickshell.env("XDG_RUNTIME_DIR")}/paleshell/agents.sock`

    // Newest first: {id, agent, cwd, project, state, prompt, tool, detail, steps, message, started, updated, pids}
    property var sessions: []
    // Oldest first: {id, sessionId, tool, detail, questions, canAlways, at, socket}
    property var approvals: []
    property bool hooksInstalled
    property bool hooksBusy
    property bool ready

    readonly property var current: approvals.length > 0 ? approvals[0] : null
    readonly property int busyCount: sessions.filter(s => s.state === "thinking" || s.state === "working").length
    readonly property bool busy: busyCount > 0

    function project(cwd: string): string {
        return cwd ? cwd.slice(cwd.lastIndexOf("/") + 1) || "/" : "";
    }

    function session(id: string): var {
        return sessions.find(s => s.id === id) ?? null;
    }

    function toolLabel(tool: string, input: var): string {
        const i = input ?? {};
        const base = p => p ? String(p).slice(String(p).lastIndexOf("/") + 1) : "";
        switch (tool) {
        case "Bash":
            return i.description || i.command || "";
        case "Read":
        case "Edit":
        case "MultiEdit":
        case "Write":
        case "NotebookEdit":
            return base(i.file_path || i.notebook_path);
        case "Grep":
        case "Glob":
            return i.pattern || "";
        case "WebFetch":
            return i.url || "";
        case "WebSearch":
            return i.query || "";
        case "Task":
        case "Agent":
            return i.description || "";
        case "ExitPlanMode":
            return i.plan || "";
        default:
            return "";
        }
    }

    function toolVerb(tool: string): string {
        const verbs = {
            Bash: Tr.tr("Running"),
            Read: Tr.tr("Reading"),
            Edit: Tr.tr("Editing"),
            MultiEdit: Tr.tr("Editing"),
            Write: Tr.tr("Writing"),
            NotebookEdit: Tr.tr("Editing"),
            Grep: Tr.tr("Searching"),
            Glob: Tr.tr("Finding"),
            WebFetch: Tr.tr("Fetching"),
            WebSearch: Tr.tr("Searching the web"),
            Task: Tr.tr("Delegating"),
            Agent: Tr.tr("Delegating"),
            TodoWrite: Tr.tr("Planning")
        };
        return verbs[tool] ?? tool;
    }

    // "Editing Ai.qml"; Bash already reads as an action through its description
    function describe(tool: string, detail: string): string {
        if (tool === "Bash")
            return detail || toolVerb(tool);
        return `${toolVerb(tool)} ${detail}`.trim();
    }

    function upsert(id: string, patch: var): var {
        const now = Date.now();
        const old = session(id);
        const next = Object.assign({
            id,
            agent: "claude",
            cwd: "",
            project: "",
            state: "idle",
            prompt: "",
            tool: "",
            detail: "",
            steps: [],
            message: "",
            started: now,
            pids: []
        }, old ?? {}, patch, {
            updated: now
        });
        if (next.cwd)
            next.project = project(next.cwd);
        sessions = [next].concat(sessions.filter(s => s.id !== id));
        return next;
    }

    function addStep(id: string, text: string): void {
        const s = session(id);
        if (s && text)
            upsert(id, {
                steps: s.steps.concat([text]).slice(-4)
            });
    }

    function removeSession(id: string): void {
        sessions = sessions.filter(s => s.id !== id);
        clearApprovals(id);
    }

    function clearApprovals(sessionId: string): void {
        if (approvals.some(a => a.sessionId === sessionId))
            approvals = approvals.filter(a => a.sessionId !== sessionId);
    }

    function handle(line: string, sock: var): void {
        let e;
        try {
            e = JSON.parse(line);
        } catch (err) {
            return;
        }
        if (e.hook_event_name !== "PermissionRequest")
            sock.connected = false;
        const id = e.session_id;
        if (!id)
            return;
        const base = {
            agent: e.agent || "claude",
            cwd: e.cwd || session(id)?.cwd || "",
            pids: e.pids?.length ? e.pids : (session(id)?.pids ?? [])
        };

        switch (e.hook_event_name) {
        case "SessionStart":
            upsert(id, Object.assign(base, {
                state: "idle"
            }));
            break;
        case "UserPromptSubmit":
            clearApprovals(id);
            upsert(id, Object.assign(base, {
                state: "thinking",
                prompt: e.prompt || "",
                tool: "",
                detail: "",
                steps: [],
                message: ""
            }));
            break;
        case "PreToolUse":
            upsert(id, Object.assign(base, {
                state: approvals.some(a => a.sessionId === id) ? "waiting" : "working",
                tool: e.tool_name || "",
                detail: toolLabel(e.tool_name, e.tool_input)
            }));
            break;
        case "PostToolUse":
        case "PostToolUseFailure":
            clearApprovals(id);
            addStep(id, describe(e.tool_name, toolLabel(e.tool_name, e.tool_input)));
            upsert(id, Object.assign(base, {
                state: "working"
            }));
            break;
        case "PermissionRequest":
            if (!sock || !e.paleshell_id)
                break;
            upsert(id, Object.assign(base, {
                state: "waiting",
                tool: e.tool_name || "",
                detail: toolLabel(e.tool_name, e.tool_input)
            }));
            approvals = approvals.concat([
                {
                    id: e.paleshell_id,
                    sessionId: id,
                    tool: e.tool_name || "",
                    detail: e.tool_name === "Bash" ? (e.tool_input?.command ?? "") : toolLabel(e.tool_name, e.tool_input),
                    description: e.tool_name === "Bash" ? (e.tool_input?.description ?? "") : "",
                    questions: e.tool_name === "AskUserQuestion" ? (e.tool_input?.questions ?? []) : [],
                    canAlways: (e.permission_suggestions?.length ?? 0) > 0,
                    at: Date.now(),
                    socket: sock
                }
            ]);
            Mascot.react("shocked");
            break;
        case "Notification":
            if (e.notification_type === "idle_prompt")
                upsert(id, Object.assign(base, {
                    state: "idle"
                }));
            break;
        case "Stop":
            clearApprovals(id);
            upsert(id, Object.assign(base, {
                state: "done",
                tool: "",
                detail: "",
                message: e.last_assistant_message || ""
            }));
            if (NotchSettings.values.agentOsd)
                NotchOsd.show("agent", "task_alt", Tr.tr("Claude finished · %1").arg(project(base.cwd)), -1);
            Mascot.react("happy");
            break;
        case "StopFailure":
            clearApprovals(id);
            upsert(id, Object.assign(base, {
                state: "error",
                message: e.error || e.message || ""
            }));
            Mascot.react("sad");
            break;
        case "SessionEnd":
            removeSession(id);
            break;
        case "SubagentStart":
            addStep(id, Tr.tr("Subagent started"));
            break;
        }
    }

    function reply(approvalId: string, data: var): void {
        const a = approvals.find(x => x.id === approvalId);
        if (!a)
            return;
        approvals = approvals.filter(x => x.id !== approvalId);
        try {
            a.socket.write(JSON.stringify(Object.assign({
                id: approvalId
            }, data)) + "\n");
            a.socket.flush();
            a.socket.connected = false;
        } catch (err) {}
        const s = session(a.sessionId);
        if (s)
            upsert(s.id, {
                state: data.decision === "deny" ? "thinking" : "working"
            });
    }

    function allow(approvalId: string): void {
        reply(approvalId, {
            decision: "allow"
        });
    }

    function always(approvalId: string): void {
        reply(approvalId, {
            decision: "always"
        });
    }

    function deny(approvalId: string): void {
        reply(approvalId, {
            decision: "deny"
        });
    }

    function answer(approvalId: string, answers: var): void {
        reply(approvalId, {
            decision: "answer",
            answers
        });
    }

    // Lets the terminal take over: closing the connection makes the hook exit with no decision
    function skip(approvalId: string): void {
        const a = approvals.find(x => x.id === approvalId);
        if (!a)
            return;
        approvals = approvals.filter(x => x.id !== approvalId);
        a.socket.connected = false;
    }

    function dropSocket(sock: var): void {
        if (approvals.some(a => a.socket === sock))
            approvals = approvals.filter(a => a.socket !== sock);
    }

    function focusTerminal(s: var): void {
        if (!s)
            return;
        const wins = Hypr.toplevels.values;
        for (const pid of s.pids ?? []) {
            const w = wins.find(t => t.lastIpcObject?.pid === pid);
            if (w) {
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "address:0x${w.address}" })` : `focuswindow address:0x${w.address}`);
                return;
            }
        }
    }

    function installHooks(install: bool): void {
        if (hooksBusy)
            return;
        hooksBusy = true;
        hooksProc.command = ["python3", "-I", Quickshell.shellPath("assets/agent-hooks.py"), install ? "install" : "uninstall"];
        hooksProc.running = true;
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", socketPath.slice(0, socketPath.lastIndexOf("/"))]);
        hooksProc.command = ["python3", "-I", Quickshell.shellPath("assets/agent-hooks.py"), "status"];
        hooksProc.running = true;
    }

    SocketServer {
        active: root.ready
        path: root.socketPath
        handler: Socket {
            id: sock

            parser: SplitParser {
                onRead: data => root.handle(data, sock)
            }

            onConnectedChanged: {
                if (!connected)
                    root.dropSocket(sock);
            }
        }
    }

    // Lets mkdir finish before the server binds
    Timer {
        running: true
        interval: 500
        onTriggered: root.ready = true
    }

    // Forget sessions nobody closed (terminal killed) after 2 h of silence
    Timer {
        running: root.sessions.length > 0
        repeat: true
        interval: 60000
        onTriggered: {
            const limit = Date.now() - 2 * 3600000;
            const stale = root.sessions.filter(s => s.updated < limit && s.state !== "waiting");
            if (stale.length > 0)
                root.sessions = root.sessions.filter(s => !stale.includes(s));
        }
    }

    Process {
        id: hooksProc

        stdout: StdioCollector {
            onStreamFinished: root.hooksInstalled = text.trim() === "installed"
        }
        onExited: root.hooksBusy = false
    }
}
