# Andrea Alberti, 2024

function __fzf_atclone_hook() {
  # On update, `dl` runs after this hook, so the man pages may not exist yet:
  # symlink rather than copy. `lbin` sets +x on the scripts.
  ln -sf "$PWD/fzf.1" "$PWD/fzf-tmux.1" "$ZPFX/man/man1/"


  # Generate completion and key-bindings scripts in one single file
  ./fzf --zsh > init.zsh
}

__fzf_atclone_hook