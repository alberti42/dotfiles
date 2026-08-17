# Pi coding agent — internals (reverse-engineered)

Notes on how the Pi coding agent (`pi`, package `@earendil-works/pi-coding-agent`,
observed at **v0.80.3**) stores sessions and loads extensions. Reverse-engineered
from the installed package under
`~/.npm-global/lib/node_modules/@earendil-works/pi-coding-agent/dist/`. Line
numbers drift between versions — search by symbol, not offset.

---

## Session storage

- Sessions are **JSONL** files, one record per line, at:
  ```
  <agentDir>/sessions/<cwd-slug>/<timestamp>_<uuid>.jsonl
  ```
  - `agentDir` = `$PI_CODING_AGENT_DIR` or `~/.pi/agent` (`config.js:getAgentDir`).
  - `cwd-slug` = `--<cwd, leading slash stripped, then / \ : → ->--`
    (`session-manager.js:getDefaultSessionDirPath`). E.g. `/Users/andrea/Nextcloud`
    → `--Users-andrea-Nextcloud--`. Spaces are preserved.
  - The session dir can be overridden with `--session-dir` / `$PI_CODING_AGENT_SESSION_DIR`.
- **First record** is the header: `{"type":"session","version":3,"id":"<uuid>","timestamp":…,"cwd":…}`.
  The rest are `message`, `model_change`, `thinking_level_change`, `session_info`, etc.
- **Writes are append-only** in normal operation (`_persist` → `appendFileSync`).
  Full rewrites (`_rewriteFile`) happen only on load-time **migration** and on
  **compaction / tree-navigation** (which serialize the in-memory entry list).
- A **fresh** session is not flushed to disk until it has real content (the first
  assistant message); before that, appends are buffered in memory.

### Where the session *name* lives

- The display name is **not** in the header. It is the `name` field of the
  **last** `session_info` record in the file (`session-manager.js`):
  ```json
  {"type":"session_info","id":"<8-hex>","parentId":"<prev leaf id>","timestamp":"…Z","name":"<title>"}
  ```
- `getSessionName()` scans `getEntries()` — which returns entries in **file order**,
  not tree order — in reverse and returns the last `session_info` name.
  **Last-write-wins.** An empty name clears the title.
- Consequence: appending one more `session_info` line renames the session on next
  load. `parentId` is irrelevant to name resolution (tree structure only); `id`
  must be unique within the file (Pi uses `randomUUID().slice(0,8)`).

### Three ways the name gets set (all funnel to the same in-memory call)

1. **RPC command** (JSON Lines over `pi --mode rpc` stdin/stdout):
   `{"type":"set_session_name","name":"…"}` → `session.setSessionName` (rejects empty).
   Emits `{"type":"session_info_changed","name":…}` then a `{"type":"response",…,"success":true}`.
2. **Extension API**: `pi.setSessionName(name)` (see below) — same `session.setSessionName`.
3. **`/name <name>` slash command**: intercepted by the **pi-acp adapter** (not core
   pi) inside its `prompt()` handler; it calls `setSessionName` and does *not*
   forward the text to the model. This is the only path reachable by typing into an
   agent-shell prompt.

All three call `sessionManager.appendSessionInfo(name)` and fire `session_info_changed`.

---

## The pi-acp bridge (agent-shell / ACP)

- Emacs `agent-shell` does **not** talk to `pi` directly. It speaks **ACP**
  (`acp.el`) to the **`pi-acp`** adapter
  (`~/.npm-global/lib/node_modules/pi-acp/dist/index.js`), which spawns
  `pi --mode rpc --no-themes` and translates.
- ACP has **no** rename request (`acp.el` has makers for
  new/prompt/set-mode/set-model/set-config/resume/fork/list/load/delete/cancel — nothing for a name).
  pi-acp's `set_session_name` bridge (`index.js:setSessionName`) is Pi-native RPC,
  reachable from Emacs only via the `/name` prompt interception above.
- When the name changes, pi-acp emits an ACP `session/update` with
  `sessionUpdate: "session_info_update", title: <name>` — that is what an ACP
  client (agent-shell) can use to refresh its displayed title.
- `pi-acp` does **not** pass `--no-extensions`, so globally-discovered extensions
  (below) load in the agent-shell-spawned session too.

---

## Extensions

An extension is a **`.ts` or `.js` module whose default export is a factory**
`(pi: ExtensionAPI) => void | Promise<void>` (`core/extensions/types.d.ts`,
`loader.js`). Pi bundles **Bun + jiti** and runs TypeScript **directly — no build
step, no type-check**. Bundled modules are exposed as *virtual imports* (so an
extension can `import { Type } from "typebox"` and
`import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"` with nothing
installed; an editor's TS server will flag these as unresolved — harmless).

### Discovery (auto-loaded, no `pi install` needed)

`discoverAndLoadExtensions` scans, in order (`loader.js`):
1. Project-local: `<cwd>/.pi/extensions/`
2. **Global: `<agentDir>/extensions/`** (i.e. `~/.pi/agent/extensions/`)
3. Explicitly configured `-e <path>` / settings entries

Accepted layouts (`isExtensionFile` / `resolveExtensionEntry`): a single `.ts`/`.js`
file; a directory with `index.ts`/`index.js`; or a directory with a `package.json`
carrying a `"pi"` field (multi-file packages). `pi install <source>` is only for
pulling from npm/git and recording in `settings.json`; it is **not** required for a
file dropped in the global dir.

### Registering an LLM-callable tool

`pi.registerTool(tool: ToolDefinition)` (`types.d.ts`). Key fields:

- `name` (used in tool calls), `label` (UI), `description` (for the model),
  `promptSnippet?` (one-liner in the system-prompt tool list), `parameters`
  (a **TypeBox** `TSchema`, e.g. `Type.Object({ name: Type.String() })`),
- `execute(toolCallId, params, signal, onUpdate, ctx): Promise<AgentToolResult>`.

`AgentToolResult` (from `@earendil-works/pi-agent-core`, `types.d.ts`):
```ts
{ content: (TextContent | ImageContent)[]; details: T; terminate?: boolean }
// TextContent = { type: "text"; text: string }
```
There is **no `isError` field** — surface problems as `content` text. `details` is
required (use `null` when you have nothing structured).

### `ExtensionAPI` highlights (in-process, race-free)

Beyond `registerTool`: `registerCommand`, `registerShortcut`, `registerFlag`,
lifecycle `on(event, handler)` (session_start, turn_end, tool_call, …),
`sendMessage` / `sendUserMessage`, `appendEntry`, `setLabel`, `exec`,
`getActiveTools`/`setActiveTools`, `setModel`, and:
- **`setSessionName(name)`** / **`getSessionName()`** — set/read the session title
  live (the same `session.setSessionName`; persists + fires `session_info_changed`).

This in-process path is race-free, unlike editing the JSONL file externally (an
external append can be clobbered by a later compaction/tree-nav rewrite, and won't
update a live session's in-memory name).

---

## Local wiring (this machine)

- **`~/.pi/agent/extensions/session-namer.ts`** — generic tool `set_session_name({name})`
  → `pi.setSessionName`. Content/harness-agnostic; the *format* of the name is the
  caller's concern.
- **`~/.pi/agent/skills` → `~/.config/opencode/skills`** (dotfiles repo), shared with
  OpenCode; `~/.claude/skills/*` symlink into the same tree. The **arxiv-paper**
  skill's `SKILL.md` instructs the agent to call `set_session_name` with
  `[<ARXIV_ID>] <title>` (version-pinned id from `fetch_arxiv.sh`), and to skip
  silently when no such tool exists (OpenCode lacks it).

### How to verify an extension loads

`pi` reports load failures on startup: `Failed to load extension "<path>": …`.
A clean (silent) start means the factory ran and `registerTool` succeeded. There is
no RPC command that lists tools; `get_state` reports `sessionName`/`sessionFile`
but not the tool set. Confirm a rename with:
```sh
printf '%s\n' '{"type":"set_session_name","name":"X"}' '{"type":"get_state"}' \
  | pi --mode rpc --session <file-or-id> --offline
```
(use a throwaway `--session-dir` to avoid touching real sessions).

---

## Useful source files

- `dist/core/session-manager.js` — session file format, `appendSessionInfo`,
  `getSessionName`, `getEntries`, `_persist`, `_rewriteFile`, slug.
- `dist/core/agent-session.js` — `setSessionName`; the runtime API object passed to
  extensions (`setSessionName`, `appendEntry`, tool management, …).
- `dist/core/extensions/{types.d.ts,loader.js,runner.js}` — extension API, discovery, tool defs.
- `dist/modes/rpc/rpc-mode.js` — RPC command dispatch (`set_session_name`, `get_state`, `prompt`, …).
- `pi-acp/dist/index.js` (separate package) — ACP ↔ pi bridge, `/name` interception,
  `session_info_update`.
