#!/usr/bin/env -S zsh -fd

# Check if running inside tmux
if [[ -z "$TMUX" ]]; then
  echo "Please run the script from inside a tmux session"
  exit 1
fi

# Define the resurrect directory
local RESURRECT_SHARE_DIR="$HOME/.local/share/tmux/resurrect"

# Configure the path to tmux resurrect plugin
local RESURRECT_PLUGIN_PATH="$1"

# Check that the directory exists
if [[ ! -f "${RESURRECT_PLUGIN_PATH}" ]]; then
  echo "Please provide the path to tmux plugin: resurrect.tmux"
  exit 1
fi

# Configure dir to tmux resurrect plugin
local RESURRECT_PLUGIN_DIR=$(dirname "${RESURRECT_PLUGIN_PATH}")

# Declare an associative array to store timestamp-to-file mappings
local -A timestamp_map

# Generate a list of timestamps in human-readable format and store mappings
local formatted_list=()
local timestamp human_readable
while IFS= read -r file; do
  timestamp=${file:t:s/tmux_resurrect_//}
  timestamp=${timestamp%.txt}  # Strip .txt extension
  # Convert YYYYMMDDTHHMMSS -> YYYY-MM-DD HH:MM:SS using zsh substring slicing
  human_readable="${timestamp[1,4]}-${timestamp[5,6]}-${timestamp[7,8]} ${timestamp[10,11]}:${timestamp[12,13]}:${timestamp[14,15]}"
  formatted_list+=("$human_readable")
  timestamp_map[$human_readable]=$file
done < <(find $(realpath "$RESURRECT_SHARE_DIR") -type f -name 'tmux_resurrect_*.txt' | sort -r)

# Create a temporary file to store mappings (workaround for fzf's separate context)
local mapping_file=$(mktemp)
for key in "${(@k)timestamp_map}"; do
  echo "$key|${timestamp_map[$key]}" >> "$mapping_file"
done

# fzf preview command: Read mapping from file and display content
fzf_preview_cmd="
  local selected={}
  local selected_file
  # Read the mapping file line by line
  while IFS='|' read -r timestamp filepath; do
    if [[ "\$selected" == "\$timestamp" ]]; then
      selected_file="\$filepath"
      break
    fi
  done < '$mapping_file'
  awk -F\"\\t\" 'BEGIN { printf \"%-10s %-6s %s\\n\", \"Session\", \"Win#\", \"Directory\" }
    /^pane/ { dir = (\$8 ~ /^:/ ? substr(\$8, 2) : \$8); printf \"%-10s %-6s %s\\n\", \$2, \$3, dir }' "\$selected_file"
"

local timestamp_width=19
local border_width=11
local padding=10
local pane_width=$(tmux display -p "#{pane_width}")
local free_pane_width=$((pane_width - border_width - timestamp_width - padding))

# Show fzf in a tmux popup with a preview window
selected_human_readable=$(printf "%s\n" "${formatted_list[@]}" | fzf-tmux -p 100%,40% --preview "$fzf_preview_cmd" --preview-window=right:${free_pane_width} --prompt="Resurrect snapshot: ")

# Get the original file path
if [[ -n "$selected_human_readable" ]]; then
  selected_file=${timestamp_map[$selected_human_readable]}
  cp -f "$selected_file" "${RESURRECT_SHARE_DIR}/last"
  # Launch restore.sh script
  "${RESURRECT_PLUGIN_DIR}/scripts/restore.sh"
fi
