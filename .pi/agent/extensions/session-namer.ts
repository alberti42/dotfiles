// session-namer.ts — Generic "rename current session" tool for Pi.
//
// Registers an LLM-callable tool `set_session_name` that renames the current
// coding-agent session in-process: it calls `pi.setSessionName`, which appends a
// `session_info` record to the session file (last-write-wins) and emits
// `session_info_changed`. Any attached UI updates live — e.g. agent-shell in
// Emacs receives the `session_info_update` over ACP and refreshes the title.
//
// Harness-agnostic and content-agnostic: any skill that has decided on a good
// title can call it. The *format* of the name is the caller's concern (see, e.g.,
// the arxiv-paper skill) — this tool just applies whatever string it is given.
//
// Auto-loaded from the global extensions dir (~/.pi/agent/extensions/); no
// `pi install` needed.

import { Type } from "typebox";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function sessionNamer(pi: ExtensionAPI): void {
  pi.registerTool({
    name: "set_session_name",
    label: "Set session name",
    description:
      "Rename the current session to a short, descriptive title. Use once you have " +
      "determined a meaningful name for the work in this session (for example, after " +
      "identifying the document or task at hand). The title is shown in the session " +
      "selector and any attached UI. Pass the full title as a single string; the " +
      "format is up to the caller.",
    promptSnippet:
      "set_session_name(name): rename the current session to a descriptive title.",
    parameters: Type.Object({
      name: Type.String({ description: "The new session title." }),
    }),
    async execute(_toolCallId, { name }) {
      const trimmed = name.replace(/[\r\n]+/g, " ").trim();
      if (!trimmed) {
        return {
          content: [{ type: "text", text: "Session name cannot be empty; nothing was changed." }],
          details: null,
        };
      }
      pi.setSessionName(trimmed);
      return {
        content: [{ type: "text", text: `Session renamed to: ${trimmed}` }],
        details: null,
      };
    },
  });
}
