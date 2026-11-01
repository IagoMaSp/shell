#!/usr/bin/env python3
"""Print recent sessions of an AI coding CLI as JSON (newest first).

Usage: ai-sessions.py <claude|antigravity> [limit]

Each session is {id, mtime (ms), cwd, title, prompt, entrypoint}. Sessions whose directory no
longer exists are skipped.
"""

import json
import os
import sqlite3
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import unquote, urlparse

PROVIDER = sys.argv[1] if len(sys.argv) > 1 else "claude"
LIMIT = int(sys.argv[2]) if len(sys.argv) > 2 else 8
HOME = Path.home()


def claude_sessions():
    # Transcripts can be tens of MB, so only the head (cwd/entrypoint) and tail (latest title/prompt)
    # of each file are read
    chunk = 256 * 1024
    projects = Path(os.environ.get("CLAUDE_CONFIG_DIR", HOME / ".claude")) / "projects"

    def entries(data: bytes):
        for line in data.split(b"\n"):
            try:
                yield json.loads(line)
            except ValueError:
                continue

    files = sorted(projects.glob("*/*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)
    for path in files:
        try:
            size = path.stat().st_size
            with path.open("rb") as f:
                head = f.read(chunk)
                if size > chunk * 2:
                    f.seek(size - chunk)
                tail = f.read() if size > chunk else b""
        except OSError:
            continue

        info = {"cwd": "", "entrypoint": "", "title": "", "prompt": ""}
        for entry in entries(head + b"\n" + tail):
            kind = entry.get("type")
            if not info["cwd"] and entry.get("cwd"):
                info["cwd"] = entry["cwd"]
                info["entrypoint"] = entry.get("entrypoint", "")
            if kind == "custom-title" and entry.get("customTitle"):
                info["title"] = entry["customTitle"]
            elif kind == "summary" and entry.get("summary") and not info["title"]:
                info["title"] = entry["summary"]
            elif kind == "last-prompt" and entry.get("lastPrompt"):
                info["prompt"] = entry["lastPrompt"]

        # Claude Desktop's internal scratch workspaces aren't real projects
        if "/.config/Claude/" in info["cwd"]:
            continue
        yield {"id": path.stem, "mtime": int(path.stat().st_mtime * 1000), **info}


def antigravity_sessions():
    db = HOME / ".gemini" / "antigravity-cli" / "conversation_summaries.db"
    if not db.exists():
        return
    conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    rows = conn.execute(
        "SELECT conversation_id, title, preview, last_modified_time, workspace_uris, source "
        "FROM conversation_summaries WHERE nesting_depth = 0 ORDER BY last_modified_time DESC"
    )
    for cid, title, preview, modified, uris, source in rows:
        try:
            cwd = unquote(urlparse(json.loads(uris)[0]).path)
        except (ValueError, IndexError, TypeError):
            continue
        try:
            # Go writes nanoseconds, which fromisoformat doesn't accept
            date, frac = modified.split(".", 1)
            stamp = datetime.fromisoformat(f"{date}.{frac[:6]}{frac[frac.index('+'):]}")
            mtime = int(stamp.timestamp() * 1000)
        except ValueError:
            mtime = 0
        yield {"id": cid, "mtime": mtime, "cwd": cwd, "title": title, "prompt": preview, "entrypoint": source}


sources = {"claude": claude_sessions, "antigravity": antigravity_sessions}
sessions = []
for session in sources.get(PROVIDER, lambda: [])():
    if len(sessions) >= LIMIT:
        break
    if session["cwd"] and os.path.isdir(session["cwd"]):
        sessions.append(session)

json.dump(sessions, sys.stdout, ensure_ascii=False)
