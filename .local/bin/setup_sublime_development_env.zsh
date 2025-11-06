#!/usr/bin/env -S zsh -d

# Workspace
WS="s"

# --- Collect window IDs ---
wezterm_id=$(aerospace list-windows --app-bundle-id com.github.wez.wezterm --monitor all --json \
    | jq '.[0]."window-id"')
sublime_id=$(aerospace list-windows --app-bundle-id com.sublimetext.4 --monitor all --json \
    | jq '.[0]."window-id"')

# --- Move them to workspace $WS to ensure the correct order ---
aerospace move-node-to-workspace --window-id $sublime_id $WS 2> /dev/null
aerospace move-node-to-workspace --window-id $wezterm_id $WS 2> /dev/null

# --- Switch to the workspace ---
aerospace workspace $WS 2> /dev/null

# --- Flatten the workspace (reset) ---
aerospace flatten-workspace-tree --workspace $WS

# --- Enforce horizontal layout ---
aerospace layout tiles vertical

# –-- Create layout in a reproducible manner ---
aerospace move up --window-id $sublime_id

# --- Focus on Sublime ---
aerospace focus --window-id $sublime_id

# --- Compute WezTerm target height = 20% of visible screen height ---
# Get the AppKit NSScreen index (1-based) for the *focused* workspace/monitor
nss_idx=$(aerospace list-workspaces --focused --format '%{monitor-appkit-nsscreen-screens-id}')

# --- Ask AppKit for that screen's visible height and take 20% (returns an integer) ---
wezterm_target_h=$(osascript -l JavaScript <<EOF
ObjC.import('AppKit')
let idx = parseInt("$nss_idx")
let screen = $.NSScreen.screens.objectAtIndex(idx - 1)
Math.round(screen.visibleFrame.size.height * 0.2)
EOF
)

# --- Fallback if anything went wrong ---
if [[ -z "$wezterm_target_h" || "$wezterm_target_h" -le 0 ]]; then
  wezterm_target_h=300
fi

# --- Resize WezTerm (absolute) ---
aerospace resize --window-id "$wezterm_id" height "$wezterm_target_h"
