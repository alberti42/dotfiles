# Copyright (c) 2025, Andrea Alberti

ssh-tmux() {
  emulate -LR zsh

  # This function intelligently determines the dark mode setting before connecting via SSH.
  local __dark_mode

  # Check if we are currently inside a tmux session by testing the $TMUX variable.
  if [ -n "$TMUX" ]; then
    # If YES, get the setting directly from the local tmux option.
    read -r __dark_mode < <(tmux show-options -vq @dark_appearance)
    # Default to 0 if the option isn't set.
    : "${__dark_mode:=0}"
  else
    # If NO, fall back to using the shell's environment variable.
    __dark_mode=${DARK_APPEARANCE:-0}
  fi

  # Connect via SSH, passing the determined value to the new remote tmux session.
  ssh -t "$@" "tmux new-session -A -s'main' \; set-option -q @dark_appearance ${__dark_mode}"
}
