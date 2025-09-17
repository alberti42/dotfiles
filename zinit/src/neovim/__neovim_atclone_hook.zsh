# Andrea Alberti, 2025

function __neovim_atclone_hook() {
  if [[ ! $(command -v fd 2> /dev/null) ]]; then
    echo "$ZINIT[col-failure]Installation failed:$ZINIT[col-rst] $ZINIT[col-id-as]neovim$ZINIT[col-rst] requires $ZINIT[col-id-as]fd$ZINIT[col-rst]. Make sure to first install $ZINIT[col-id-as]sharkdp/fd$ZINIT[col-rst] package."
    return 1
  fi

  command mv nvim-*/* . &&
  command rm -r nvim-* &&
  command fd -t x -X chmod a-x &&
  command chmod u+x bin/nvim &&
  command cp "${${(%):-%x}:h}/neovim_shim.zsh" bin/ &&
  command cp -vf share/man/man1/nvim.1 $ZINIT[MAN_DIR]/man1
}

_safe_one_off_load __neovim_atclone_hook
