# Andrea Alberti, 2024

function __fzf_atclone_hook() {
  # Make the downloaded scripts executable
  chmod +x fzf-tmux fzf-preview.sh

  # Now that the files from `dl` exist, copy the man pages
  # Use -f to avoid errors if they already exist.
  cp -f fzf.1 "$ZPFX/man/man1/"
  cp -f fzf-tmux.1 "$ZPFX/man/man1/"
  
  # Generate completion and key-bindings scripts in one single file
  ./fzf --zsh > init.zsh
}

__fzf_atclone_hook