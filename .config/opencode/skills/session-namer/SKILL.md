---
name: session-namer
description: List and rename Claude Code sessions from the transcript files, so the /resume picker shows meaningful titles instead of the auto-generated one every branch inherits. Use whenever the user asks to rename a session (this one or another), to find which past session did some piece of work, or to clean up duplicate session titles. Claude Code only — under Pi, call the built-in set_session_name tool instead.
---

# Name a Claude Code session

Auto-titles are generated once from the opening message and never revised, so
every branch, fork and resume of a conversation inherits the same string. Fix it
by writing a real title.

## First: is `set_session_name` in your tools?

If yes, you are running under Pi — **call that tool and stop reading**. It renames
the live session in-process and pushes the new title to any attached UI (agent-shell
in Emacs updates over ACP). The script below writes Claude Code transcripts under
`~/.claude/projects/`, which are not Pi's session files, so it cannot rename a Pi
session — and a Pi session renamed by hand would not notify the UI.

Use the script only when that tool is absent (plain Claude Code), or to rename a
session other than the current one, which the Pi tool does not do.

## How to run (do this — don't reimplement)

```sh
SN=~/.claude/skills/session-namer/session_namer.py

python3 "$SN" list                       # recent sessions for the cwd, newest first
python3 "$SN" list -n 30 --project ~/org # another working directory
python3 "$SN" rename 6f2d0bff "Vault git backup"
```

`list` prints `id  date  count  title` plus the first real user message — that
line is what identifies a session, not the title. A `*` marks sessions still
carrying an auto-title. `rename` accepts any unambiguous id prefix.

## What it does

A title is one appended record: `{"type":"custom-title","customTitle":…}`, last
one wins. So renaming appends, never rewrites; the session may be running, and
`/resume` picks the new title up when reopened.

## Notes

- **This session's id** is in the scratchpad path from the system prompt
  (`…/<project>/<session-id>/scratchpad`). Use it to rename the current session
  without guessing from `list`.
- Before renaming someone else's session, read its first user message from
  `list` — several sessions usually share one auto-title.
- Deleting a session is `rm` of its `.jsonl`. Check the message count first;
  `/resume` bookkeeping alone produces sessions with no conversation. A live fork
  that has not flushed also looks empty and will reappear after deletion.
