#!/usr/bin/env -S zsh -d

# Workspace
WS="l"

# --- Collect window IDs ---
wezterm_id=$(aerospace list-windows --app-bundle-id com.github.wez.wezterm --monitor all --json \
    | jq '.[0]."window-id"')
skim_id=$(aerospace list-windows --app-bundle-id net.sourceforge.skim-app.skim --monitor all --json \
    | jq '.[0]."window-id"')
sublime_id=$(aerospace list-windows --app-bundle-id com.sublimetext.4 --monitor all --json \
    | jq '.[0]."window-id"')

# --- First move the windows out of workspace l ---
aerospace move-node-to-workspace --window-id $sublime_id 0 2> /dev/null
aerospace move-node-to-workspace --window-id $wezterm_id 0 2> /dev/null
aerospace move-node-to-workspace --window-id $skim_id 0 2> /dev/null

# --- Move them to workspace l to ensure the correct order ---
aerospace move-node-to-workspace --window-id $sublime_id $WS 2> /dev/null
aerospace move-node-to-workspace --window-id $wezterm_id $WS 2> /dev/null
aerospace move-node-to-workspace --window-id $skim_id $WS 2> /dev/null

# --- Reset layout to horizontal ---
aerospace workspace $WS 2> /dev/null

# --- Flatten the workspace (reset) ---
aerospace flatten-workspace-tree --workspace $WS

# --- Enforce horizontal layout ---
aerospace layout tiles horizontal

# –-- Create layout in a reproducible manner ---
# aerospace move left --window-id $sublime_id
# aerospace move left --window-id $sublime_id
# aerospace move right --window-id $skim_id
aerospace join-with left --window-id $wezterm_id

# --- Retrieve screen size ---
# Get the AppKit NSScreen index (1-based) for the *focused* workspace/monitor
nss_idx=$(aerospace list-workspaces --focused --format '%{monitor-appkit-nsscreen-screens-id}')

res=$(osascript -l JavaScript <<EOF
ObjC.import('AppKit');
let idx = parseInt("$nss_idx")
let screen = $.NSScreen.screens.objectAtIndex(idx - 1);
let size = screen.visibleFrame.size;
\`\${size.width}x\${size.height}\`;
EOF
)
width=${res%x*}   # remove 'x...' from the right
height=${res#*x}  # remove '...x' from the left

function round() {
echo $(printf %.$2f $(echo "scale=$2;(((10^$2)*$1)+0.5)/(10^$2)" | bc))
};

# --- Set height of WezTerm to 20% (returns an integer) ---
wezterm_target_h=$(round $((height*0.2)) 0)

# --- Fallback if anything went wrong ---
if [[ -z "$wezterm_target_h" || "$wezterm_target_h" -le 0 ]]; then
  wezterm_target_h=300
fi

# --- Resize WezTerm (absolute) ---
aerospace resize --window-id "$wezterm_id" height "$wezterm_target_h"

# --- Set width of Skim to 40% (returns an integer) ---
skim_target_w=$(round $((width*0.40)) 0)

# --- Fallback if anything went wrong ---
if [[ -z "$skim_target_w" || "$skim_target_w" -le 0 ]]; then
  skim_target_w=600
fi

# --- Resize WezTerm (absolute) ---
aerospace resize --window-id "$skim_id" width "$skim_target_w"


# --- Adjust magnification in Skim
osascript -l JavaScript <<'EOF'
ObjC.import('stdlib');

var se = Application("System Events");
var skim = se.processes.byName("Skim");

skim.frontmost = true;

// navigate: menu bar 1 -> menu bar item "PDF" -> menu "PDF" -> menu item "Größe anpassen"
var menuItem = skim.menuBars[0]
    .menuBarItems["PDF"]
    .menus["PDF"]
    .menuItems["Größe anpassen"];

menuItem.click();
EOF

# --- Focus on Sublime ---
aerospace focus --window-id $sublime_id
