# Copyright (c) 2025, Andrea Alberti

ssh-tmux() {
  emulate -LR zsh

  # This function intelligently determines the dark mode setting before connecting via SSH.
  local dark_mode

  # Check if we are currently inside a tmux session by testing the $TMUX variable.
   if [[ -n $TMUX ]]; then
    # If YES, get the setting directly from the local tmux option.
    # We use read -r to read just a single line; tmux output a newline which we want to avoid
    read -r dark_mode < <(tmux show-options -gvq @dark_appearance 2>/dev/null)
    # Default to 0 if the option isn't set.
    : "${dark_mode:=0}"
  else
    # If NO, fall back to using the shell's environment variable.
    dark_mode=${DARK_APPEARANCE:-0}
  fi

  # Connect via SSH, passing the determined value to the new remote tmux session.
  ssh -t "$@" "
    tmux new-session -A -s main \; set-option -gq @dark_appearance ${dark_mode}
    tmux list-panes -a -F '#{pane_pid}' | while IFS= read -r pid; do
      [[ \$pid == <-> ]] || continue
      comm=\$(ps -p \"\$pid\" -o comm= 2>/dev/null) || continue
      [[ \$comm == zsh ]] || continue
      kill -USR1 \"\$pid\" 2>/dev/null || true
    done
  "
}
