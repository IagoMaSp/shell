#!/usr/bin/env python3
"""Claude Code hook relay for the PaleShell notch.

Claude Code runs this on every hook event (see agent-hooks.py). It forwards the
event as one JSON line to the shell's socket ($XDG_RUNTIME_DIR/paleshell/agents.sock).

Rule: never block the agent. If the shell is not listening we exit at once
with no output. Only PermissionRequest waits for an answer from the notch; with
no answer (timeout, notch closed, unknown reply) nothing is printed and Claude
Code asks in its terminal as usual. Nothing is ever allowed without a click.
"""

import json
import os
import socket
import sys

CONNECT_TIMEOUT = 0.3
SEND_TIMEOUT = 2
DECISION_TIMEOUT = 110
MAX_FIELD = 2000
DROPPED = ("tool_response", "tool_output")


def socket_path():
    runtime = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    return os.path.join(runtime, "paleshell", "agents.sock")


def clip(value, depth=0):
    if isinstance(value, str):
        return value if len(value) <= MAX_FIELD else value[:MAX_FIELD] + "…"
    if isinstance(value, dict) and depth < 6:
        return {k: clip(v, depth + 1) for k, v in value.items()}
    if isinstance(value, list) and depth < 6:
        return [clip(v, depth + 1) for v in value[:40]]
    return value


def ancestors():
    """Pids from our parent up to init, so the shell can find the terminal window."""
    pids = []
    pid = os.getppid()
    while pid > 1 and len(pids) < 16:
        pids.append(pid)
        try:
            with open(f"/proc/{pid}/stat") as f:
                pid = int(f.read().rsplit(")", 1)[1].split()[1])
        except (OSError, ValueError, IndexError):
            break
    return pids


def last_assistant_text(path):
    """Final assistant text of the transcript, read from its tail only."""
    try:
        with open(path, "rb") as f:
            f.seek(0, 2)
            f.seek(max(0, f.tell() - 256 * 1024))
            lines = f.read().decode("utf-8", "replace").splitlines()
    except OSError:
        return ""
    for line in reversed(lines):
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        msg = entry.get("message") or {}
        if entry.get("type") != "assistant" or msg.get("role") != "assistant":
            continue
        texts = [c.get("text", "") for c in msg.get("content") or [] if isinstance(c, dict) and c.get("type") == "text"]
        text = "\n".join(t for t in texts if t).strip()
        if text:
            return text
    return ""


def answers_fit(questions, answers):
    """True when answers answer exactly the questions asked, with their own labels."""
    if not isinstance(questions, list) or not questions or not isinstance(answers, dict):
        return False
    if len(questions) != len(answers):
        return False
    for q in questions:
        text = q.get("question")
        labels = [o.get("label") for o in q.get("options") or []]
        pick = answers.get(text)
        if q.get("multiSelect"):
            if not isinstance(pick, list) or not pick or len(set(pick)) != len(pick):
                return False
            if not all(isinstance(p, str) and p in labels for p in pick):
                return False
        elif not isinstance(pick, str) or pick not in labels:
            return False
    return True


def decision_output(reply, payload):
    """The documented PermissionRequest output, or None when there is no valid decision."""
    try:
        reply = json.loads(reply)
    except ValueError:
        return None
    if not isinstance(reply, dict) or reply.get("id") != payload.get("paleshell_id"):
        return None
    kind = reply.get("decision")
    if kind == "answer":
        tool_input = payload.get("tool_input") or {}
        answers = reply.get("answers")
        if payload.get("tool_name") != "AskUserQuestion" or not answers_fit(tool_input.get("questions"), answers):
            return None
        decision = {"behavior": "allow", "updatedInput": dict(tool_input, answers=answers)}
    elif kind == "allow":
        decision = {"behavior": "allow"}
    elif kind == "always":
        decision = {"behavior": "allow"}
        suggestions = payload.get("permission_suggestions")
        if isinstance(suggestions, list) and suggestions:
            decision["updatedPermissions"] = suggestions
    elif kind == "deny":
        decision = {"behavior": "deny", "message": "Denied from the PaleShell notch"}
    else:
        return None
    return json.dumps({"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": decision}})


def main():
    agent = ""
    args = sys.argv[1:]
    if "--agent" in args:
        i = args.index("--agent")
        agent = args[i + 1] if i + 1 < len(args) else ""

    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except ValueError:
        return
    if not isinstance(payload, dict):
        return

    path = socket_path()
    if not os.path.exists(path):
        return

    event = payload.get("hook_event_name", "")
    full_input = payload.get("tool_input")
    if event == "Stop" and not payload.get("last_assistant_message"):
        payload["last_assistant_message"] = last_assistant_text(payload.get("transcript_path") or "")
    for key in DROPPED:
        payload.pop(key, None)
    payload.pop("transcript_path", None)

    payload = clip(payload)
    payload["agent"] = agent or ("claude-desktop" if os.environ.get("CLAUDE_CODE_ENTRYPOINT") == "claude-desktop" else "claude")
    payload["pids"] = ancestors()
    waits = event == "PermissionRequest"
    if waits:
        payload["paleshell_id"] = f"{os.getpid()}-{os.urandom(4).hex()}"

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        sock.settimeout(CONNECT_TIMEOUT)
        sock.connect(path)
        sock.settimeout(SEND_TIMEOUT)
        sock.sendall((json.dumps(payload) + "\n").encode())
        if not waits:
            # The shell hangs up once it has the line; waiting for that keeps its log clean
            sock.settimeout(1)
            sock.recv(1)
            return
        sock.settimeout(DECISION_TIMEOUT)
        buf = b""
        while b"\n" not in buf:
            chunk = sock.recv(65536)
            if not chunk:
                return
            buf += chunk
    except OSError:
        return
    finally:
        sock.close()

    # Answers are checked against the untrimmed question, as Claude Code asked it
    if full_input is not None:
        payload["tool_input"] = full_input
    out = decision_output(buf.split(b"\n", 1)[0].decode("utf-8", "replace"), payload)
    if out:
        print(out)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)
