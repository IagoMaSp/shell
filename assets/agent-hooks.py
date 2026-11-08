#!/usr/bin/env python3
"""Install or remove the PaleShell notch hooks in Claude Code's settings.json.

Usage: agent-hooks.py status|install|uninstall [settings.json]
Prints "installed" or "missing". Only entries whose command runs agent-hook.py are
touched; the user's own hooks stay as they are. A backup is written before any change.
"""

import json
import os
import shutil
import sys
import time

RELAY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "agent-hook.py")
MARKER = "agent-hook.py"
EVENTS = {
    "SessionStart": 10,
    "SessionEnd": 10,
    "UserPromptSubmit": 10,
    "PreToolUse": 10,
    "PostToolUse": 10,
    "PostToolUseFailure": 10,
    # Waits for a click in the notch: the relay gives up after 110 s
    "PermissionRequest": 120,
    "Notification": 10,
    "Stop": 10,
    "StopFailure": 10,
    "SubagentStart": 10,
}


def settings_path():
    if len(sys.argv) > 2:
        return os.path.abspath(sys.argv[2])
    base = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~/.claude")
    return os.path.join(base, "settings.json")


def is_ours(entry):
    return any(MARKER in (h.get("command") or "") for h in entry.get("hooks") or [])


def strip(hooks):
    out = {}
    for event, entries in hooks.items():
        kept = [e for e in entries if not is_ours(e)] if isinstance(entries, list) else entries
        if kept:
            out[event] = kept
    return out


def installed(settings):
    hooks = settings.get("hooks") or {}
    return all(any(is_ours(e) for e in hooks.get(ev) or []) for ev in EVENTS)


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "status"
    path = settings_path()
    try:
        with open(path) as f:
            settings = json.load(f)
    except FileNotFoundError:
        settings = {}
    except ValueError:
        # Never overwrite a file we cannot read
        print("missing")
        return

    if action in ("install", "uninstall"):
        hooks = strip(settings.get("hooks") or {})
        if action == "install":
            command = f"python3 -I {RELAY}"
            for event, timeout in EVENTS.items():
                hooks.setdefault(event, []).append({"hooks": [{"type": "command", "command": command, "timeout": timeout}]})
        if hooks:
            settings["hooks"] = hooks
        else:
            settings.pop("hooks", None)
        if os.path.exists(path):
            shutil.copy2(path, f"{path}.bak-paleshell-{time.strftime('%Y%m%d-%H%M%S')}")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        tmp = f"{path}.tmp-paleshell"
        with open(tmp, "w") as f:
            json.dump(settings, f, indent=2)
            f.write("\n")
        os.replace(tmp, path)

    print("installed" if installed(settings) else "missing")


if __name__ == "__main__":
    main()
