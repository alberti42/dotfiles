// sound-notifier.ts — Play a sound on key Pi lifecycle events (macOS).
//
// The Pi analogue of ~/.claude/hooks/claude-notifier.py. Pi exposes lifecycle
// events to extensions via `pi.on(event, handler)` (see the core extension API),
// so no external hook process is needed — this runs in-process and just shells
// out to `afplay`.
//
// Event mapping (Pi event -> config key):
//   agent_settled              -> "complete"   (agent finished, it's your turn)
//   tool_execution_end isError -> "error"      (a tool call failed)
//
// Pi does NOT expose a user-facing permission/elicitation event to extensions,
// so the Claude "permission_prompt" / "idle_prompt" / "elicitation_dialog" keys
// have no equivalent here; only "complete" and "error" fire.
//
// Config: ~/.pi/pi-notifier.json (override with $PI_NOTIFIER_CONFIG). Same shape
// as claude-notifier.json but with Pi's keys:
//   {
//     "sound": true,                       // master switch
//     "events": { "complete": { "sound": true }, "error": { "sound": true } },
//     "sounds": { "complete": "/path/a.aiff", "error": "/path/b.aac" }
//   }
// The file is re-read on every event, so edits take effect without restarting Pi.
//
// Auto-loaded from the global extensions dir (~/.pi/agent/extensions/).

import { spawn } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type EventKey = "complete" | "error";

interface NotifierConfig {
  sound?: boolean;
  events?: Partial<Record<EventKey, { sound?: boolean }>>;
  sounds?: Partial<Record<EventKey, string>>;
}

const SYSTEM_SOUND_FALLBACKS: Record<EventKey, string> = {
  complete:
    "/Users/andrea/Documents/Programming/Others/fork-opencode.nosync/packages/ui/src/assets/audio/bip-bop-03.aac",
  error:
    "/Users/andrea/Documents/Programming/Others/fork-opencode.nosync/packages/ui/src/assets/audio/nope-01.aac",
};

function configPath(): string {
  return (
    process.env.PI_NOTIFIER_CONFIG || join(homedir(), ".pi", "pi-notifier.json")
  );
}

function loadConfig(): NotifierConfig {
  try {
    return JSON.parse(readFileSync(configPath(), "utf-8")) as NotifierConfig;
  } catch {
    return {};
  }
}

function resolveSound(cfg: NotifierConfig, key: EventKey): string | null {
  // Master switch (default on) and per-event toggle (default on).
  if (cfg.sound === false) return null;
  if (cfg.events?.[key]?.sound === false) return null;

  const candidate = cfg.sounds?.[key];
  if (candidate && existsSync(candidate)) return candidate;

  const fallback = SYSTEM_SOUND_FALLBACKS[key];
  return existsSync(fallback) ? fallback : null;
}

function play(key: EventKey): void {
  if (process.platform !== "darwin") return; // afplay is macOS-only
  const path = resolveSound(loadConfig(), key);
  if (!path) return;
  try {
    const child = spawn("/usr/bin/afplay", [path], {
      stdio: "ignore",
      detached: true,
    });
    child.on("error", () => {});
    child.unref();
  } catch {
    /* never let audio break the session */
  }
}

export default function soundNotifier(pi: ExtensionAPI): void {
  // Agent finished its run and is now idle waiting for you.
  pi.on("agent_settled", () => {
    play("complete");
  });

  // A tool call failed.
  pi.on("tool_execution_end", (event) => {
    if (event.isError) play("error");
  });
}
