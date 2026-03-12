#!/usr/bin/env -S zsh -fd

main() {
  # Path to your custom build
  local nvim_bin="$HOME/.local/share/zinit/plugins/neovim---neovim/bin/nvim"
  local vimruntime="$HOME/.local/share/zinit/plugins/neovim---neovim/share/nvim/runtime"

  # If not inside tmux → run nvim directly
  if [[ -z "$TMUX" ]]; then
    VIMRUNTIME="$vimruntime" exec "$nvim_bin" "$@"
  fi

  # Inside tmux: build a unique socket path per window
  local session_window=$(tmux display-message -p "#{session_name}-#{window_index}")

  local this_pane=$(tmux display-message -p "#{pane_id}")

  local server_dir="${XDG_CACHE_HOME:-$HOME/.cache}/nvim/tmux-openfile"
  mkdir -p "$server_dir"

  local server="$server_dir/${session_window}.sock"

  # Check if a server is alive
  if [[ -S "$server" ]] && { "$nvim_bin" -u NONE --headless --server "$server" --remote-expr '1'; } >/dev/null 2>&1; then
    # Pane ID recorded for this window (if any)
    local nvim_pane=$(tmux show-options -wqv @nvim_pane)

    # Shift focus to the stored Neovim pane
    if [[ -n "$nvim_pane" ]]; then
      if ! tmux select-pane -t "$nvim_pane" 2>/dev/null; then
        # Unset tmux @nvim_pane option
        tmux set-option -wu @nvim_pane 2>/dev/null
        # Remove socket to avoid stale files
        rm -f "$server"
        # Warn the user clearly
        echo "Error: Neovim server pane ${nvim_pane} not found in the current tmux window." >&2
        echo "Hint: 'nvim' socket has been removed. Restart Neovim in a pane with 'nvim'." >&2
        exit 1
      fi
    fi

    # Check whether the user provided some arguments
    if [[ $# -gt 0 ]]; then
      # Send arguments to the running server
      VIMRUNTIME="$vimruntime" exec "$nvim_bin" --server "$server" --remote "$@"
    fi
  else
    # Start a new server in this pane
    rm -f "$server"
    # Record this pane as the Neovim owner for this window
    tmux set-option -w @nvim_pane "$this_pane"

    VIMRUNTIME="$vimruntime" exec "$nvim_bin" "$@"
  fi
}

# Forward all arguments to main()
main "$@"
