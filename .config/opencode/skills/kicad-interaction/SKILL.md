---
name: kicad-interaction
description: >-
  How to interact with a KiCad project programmatically — the three read/edit/verify paths (direct
  S-expression/XML file edit, the MCP `kicad` server, the kicad-python IPC API `kipy`), when to pick
  each, the "KiCad is open → File → Revert" hazard, the headless-ERC bug + fixed fork build, where to
  find authoritative KiCad docs (context7), and the safety discipline that keeps file-surgery from
  silently corrupting a board. Use whenever you need to read or edit a `.kicad_pcb`/`.kicad_sch`/
  `.kicad_pro` (or an Eagle `.brd`/`.sch`), run DRC/ERC, or drive a running KiCad session — i.e. any
  programmatic KiCad work. Load this once per project (reference it from the project `CLAUDE.md`)
  rather than duplicating these rules.
---

# Interacting with KiCad programmatically

There are **three** programmatic paths to a KiCad board/schematic. Pick by task — don't add a
transport you don't need. Most work is the first one.

| Path | Backend | Use it for | Edits |
|---|---|---|---|
| **Direct file edit** | S-expr / XML text surgery | almost everything (default) | **on disk** |
| **MCP `kicad`** | SWIG `pcbnew` | DRC/ERC + read-only queries (verification) | read-only |
| **`kipy` IPC** | kicad-python, running session | safety-critical bulk edits | **live in-memory** |

## 1. Direct file edit — the default
Edit the `.kicad_pcb`/`.kicad_sch`/`.kicad_pro` S-expressions (or Eagle `.brd`/`.sch` XML) as text.
Use for almost everything: reading nets/geometry, per-pad-net changes, deleting segments, and **all
Eagle-reference parsing** (XML via Python ElementTree). It does the per-pad-net / delete-segment edits
the MCP can't. Works with KiCad **closed** (cleanest). Proven safe — but observe the discipline below
(keep paren-balance at 0; DRC after each edit).

## 2. MCP `kicad` server — for verification
Use `mcp__kicad__run_drc` / `run_erc`, `get_drc_violations`, and read-only board queries.
**Re-open the project (`mcp__kicad__open_project`) before each DRC/ERC run** so the MCP reloads the
on-disk file you just edited — its copy is otherwise stale.
- ⚠️ Coordinates are sometimes reported **÷100** (`1.905` actually means 190.5 mm).
- ⚠️ The MCP's SWIG `pcbnew` backend is **removed in KiCad 11** — it's on a deprecation clock. For
  schematic ERC it also shares the buggy headless path (see below); prefer the fork build for ERC.

## 3. kicad-python IPC API (`kipy`) — only when an edit's *safety* justifies the setup
Drives a **running** KiCad session (enable the API server in Preferences → Plugins) with a typed
object model (`pad.net`, `board.remove(item)`, `commit`) instead of S-expr text-surgery. It edits the
**live in-memory session, not disk** — so the workflow inverts:

> agent edits via IPC → **user clicks Save in KiCad** → on disk is now *downstream* of the edit → commit as usual.

No `File → Revert` dance (this is the one path where disk follows the edit). **Don't mix it with the
direct-file-edit flow on the same board in one pass.**

- **Worth it for:** bulk/repeated pad-net or item-removal edits where a text typo would silently
  corrupt the file; agent-driven board work that must survive KiCad 11 (IPC replaces SWIG `pcbnew`).
- **Not worth it for:** a handful of one-off fixes (direct file-edit is faster), schematic work (IPC
  schematic support is still "initial"), or ERC (use the fork build).
- **Dedicated env:** its `protobuf>=5.29,<6` pin conflicts with tensorflow/numbers-parser, so it is
  **not** in `py313`. Use interpreter `~/.pyenv/versions/3.13.1/envs/kicad-api/bin/python`
  (pyenv-virtualenv `kicad-api`). **Do not** `pip install kicad-python` into `py313` — it downgrades
  protobuf and breaks tensorflow there.

## ⚠️ The "KiCad is open" hazard — File → Revert
Direct file edits (path 1) and our Python scripts change the files **on disk**, but KiCad keeps an
**in-memory** copy. If KiCad is open while you edit on disk:
- KiCad's copy goes **stale**, and if the user saves it they'll **overwrite your edits**.
- After any on-disk edit the user must do **File → Revert** in KiCad to reload from disk (and must NOT
  save the stale copy first).
- A `~*.lck` lock file exists whenever the project is open — **check for it before editing**.
- **Cleanest: edit while KiCad is closed.** (The `kipy` IPC path is the exception — it *needs* KiCad
  open and is downstream of disk; see path 3.)

## ⚠️ Headless-ERC bug — verify schematic ERC with the FIXED fork build
The released `kicad-cli` (`/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli`) and
`mcp__kicad__run_erc` share the **headless ERC path**, which **falsely reports `wire_dangling` /
unconnected-pin errors** on designs that use **hierarchical sheet instances** (KiCad issue 24409 — the
GUI was always correct). Don't chase those phantom dangling wires. Verify ERC with the user's patched
fork build instead:

```
/Users/andrea/Documents/Programming/Others/fork-kicad/build/kicad/KiCad.app/Contents/MacOS/kicad-cli
```
(commit `eb4cfa45`). Note: `kicad-cli` is **not** on PATH.

## KiCad docs via context7 — query before guessing
Two official sources are indexed; prefer them over WebFetch for KiCad syntax/API questions (e.g.
before writing a `.kicad_dru` custom rule or calling a `kipy` method):
- **`/gitlab_kicad/code_kicad-python`** — the IPC/`kipy` API: classes, methods, examples.
- **`/gitlab_kicad/services_kicad-doc`** — the KiCad user/reference manuals: eeschema, pcbnew,
  `.kicad_dru` rule syntax, netlist/file-format details, scripting.

GUI click-paths and UI workflows live in `/gitlab_kicad/services_kicad-doc` too — look them up rather
than guessing menu locations.

## Safety discipline for direct file edits
- **Commit / back up first**, then edit. Scratch copies go in `/tmp`, not the repo.
- **Keep the parenthesis balance at 0** after every edit (S-expr files corrupt silently otherwise).
- **DRC/ERC after each edit**, re-opening the project in the MCP first (its copy is stale).
- Prefer **fixing root causes** over silencing rules; when you do silence one, document why.
- The MCP server lives at `~/Documents/Programming/Others/KiCAD-MCP-Server` (user-scope; all
  `mcp__kicad__*` allowed).
