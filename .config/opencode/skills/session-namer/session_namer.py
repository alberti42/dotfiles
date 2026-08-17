#!/usr/bin/env python3
"""session_namer.py — list and rename Claude Code sessions.

A session's title is just a record appended to its transcript
(`~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`):

    {"type": "custom-title", "customTitle": "...", "sessionId": "..."}

The last such record wins, so renaming is an append — nothing is rewritten and
no session has to be running.  `/rename` in the TUI does exactly this, but only
for the session you are sitting in; this script reaches any of them.

Usage:
    session_namer.py list [-n N] [--project DIR] [--all]
    session_namer.py rename <session-id> <title> [--project DIR]

<session-id> may be any unambiguous prefix (the 8 chars `list` prints are enough).
--project takes a working directory (default: cwd); its transcripts live in the
matching folder under ~/.claude/projects/.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path

PROJECTS = Path.home() / ".claude" / "projects"

# Wrapper text that carries no topic information.
NOISE = ("<system-reminder>", "<local-command-", "<command-", "Caveat:")


def project_dir(cwd: Path) -> Path:
    """Transcript folder for a working directory ('/' and '.' become '-')."""
    return PROJECTS / re.sub(r"[/.]", "-", str(cwd.resolve()))


def read_session(path: Path) -> dict:
    """Title, first substantive user line, and message count for one transcript."""
    title = ai_title = first = None
    messages = 0
    with path.open(encoding="utf-8", errors="replace") as fh:
        for line in fh:
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            kind = rec.get("type")
            if kind == "custom-title":
                title = rec.get("customTitle")
            elif kind == "ai-title":
                ai_title = rec.get("aiTitle")
            elif kind in ("user", "assistant"):
                messages += 1
                if kind == "user" and first is None:
                    text = message_text(rec)
                    if text:
                        first = text
    return {
        "id": path.stem,
        "title": title or ai_title or "(untitled)",
        "named": title is not None,
        "first": first or "(no conversation)",
        "messages": messages,
        "mtime": path.stat().st_mtime,
    }


def message_text(rec: dict) -> str | None:
    """Plain text of a user record, or None if it is only wrapper noise."""
    message = rec.get("message")
    if not isinstance(message, dict):
        return None
    content = message.get("content")
    if isinstance(content, list):
        content = " ".join(
            block.get("text", "")
            for block in content
            if isinstance(block, dict) and block.get("type") == "text"
        )
    if not isinstance(content, str):
        return None
    text = " ".join(content.split())
    if not text or text.startswith(NOISE):
        return None
    return text


def resolve(directory: Path, session_id: str) -> Path:
    """Find one transcript by full id or unambiguous prefix."""
    matches = sorted(directory.glob(f"{session_id}*.jsonl"))
    if not matches:
        sys.exit(f"no session starting with {session_id!r} in {directory}")
    if len(matches) > 1:
        names = ", ".join(p.stem[:8] for p in matches)
        sys.exit(f"{session_id!r} is ambiguous: {names}")
    return matches[0]


def cmd_list(args: argparse.Namespace) -> None:
    directory = project_dir(Path(args.project))
    if not directory.is_dir():
        sys.exit(f"no transcripts for {args.project} (looked in {directory})")
    sessions = sorted(
        (read_session(p) for p in directory.glob("*.jsonl")),
        key=lambda s: s["mtime"],
        reverse=True,
    )
    if not args.all:
        sessions = sessions[: args.number]
    for s in sessions:
        when = time.strftime("%d %b %H:%M", time.localtime(s["mtime"]))
        mark = " " if s["named"] else "*"  # * = still auto-titled
        print(f"{s['id'][:8]}  {when}  {s['messages']:>5} msg {mark} {s['title']}")
        print(f"          {s['first'][:100]}")


def cmd_rename(args: argparse.Namespace) -> None:
    title = " ".join(args.title.split())
    if not title:
        sys.exit("refusing to set an empty title")
    directory = project_dir(Path(args.project))
    path = resolve(directory, args.session_id)
    record = {"type": "custom-title", "customTitle": title, "sessionId": path.stem}
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(record) + "\n")
    print(f"{path.stem[:8]}  ->  {title}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)

    lst = sub.add_parser("list", help="recent sessions, newest first")
    lst.add_argument("-n", "--number", type=int, default=10)
    lst.add_argument("--all", action="store_true", help="ignore -n")
    lst.set_defaults(func=cmd_list)

    ren = sub.add_parser("rename", help="set a session's title")
    ren.add_argument("session_id", help="full id or unambiguous prefix")
    ren.add_argument("title")
    ren.set_defaults(func=cmd_rename)

    for p in (lst, ren):
        p.add_argument("--project", default=".", metavar="DIR",
                       help="working directory of the sessions (default: cwd)")

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
