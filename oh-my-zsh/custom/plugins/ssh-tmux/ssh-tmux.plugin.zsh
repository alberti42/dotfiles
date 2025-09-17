#!/hint/zsh

# Copyright (c) 2024, Andrea Alberti

# Dynamically load 'ssh-tmux' function by overwriting
# the loader function below with the actual function
function ssh-tmux() {
  emulate -LR zsh

  local loader_path="${(%):-%x}"

  # Determine the directory of the loader and append the src path
  local src_path="${loader_path:h}/src/ssh-tmux.zsh"

  # Source the actual code after determining
  # the directory of the loader and append the src path
  source "${loader_path:h}/src/ssh-tmux.zsh"

  # Overwrite this function with the actual implementation
  ssh-tmux "$@"
}

# Enforce the same autocompletion for ssh-tmux as for ssh
compdef ssh-tmux=ssh
