# Andrea Alberti, 2025

function __neovim_atclone_hook() {
  command find . -type f -perm -111 -exec chmod a-x {} + &&
  command chmod u+x bin/nvim &&
  command cp "${${(%):-%x}:h}/neovim_shim.zsh" bin/ &&
  command cp -vf share/man/man1/nvim.1 $ZINIT[MAN_DIR]/man1
}

_safe_one_off_load __neovim_atclone_hook
