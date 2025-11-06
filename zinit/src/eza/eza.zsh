# https://github.com/eza-community/eza

function __eza_init_hook() {
  local _eza_params=(
    '--git'
    '--group'
    '--group-directories-first'
    '--time-style=long-iso'
    '--icons'
  )

  alias ls="eza ${_eza_params[*]}"
  alias l="eza --long ${_eza_params[*]}"
  alias ll="eza --long --all --header ${_eza_params[*]}"
  alias llm="eza --all --header --long --sort=modified ${_eza_params[*]}"
  alias lls="eza --all --header --long --sort=size --reverse ${_eza_params[*]}"
  alias la="eza -lbhHigUmuSa"
  alias lx="eza -lbhHigUmuSa@"
  alias tree="eza --tree ${_eza_params[*]}"

  # Use zinit hijacking of compdef to just do book-keeping
  # and delay execution of compdef to the end for one time
  :zinit-tmp-subst-compdef l=eza
  :zinit-tmp-subst-compdef ll=eza
  :zinit-tmp-subst-compdef llm=eza
  :zinit-tmp-subst-compdef lls=eza
  :zinit-tmp-subst-compdef la=eza
  :zinit-tmp-subst-compdef lx=eza
  :zinit-tmp-subst-compdef tree=eza

  # Needed under macOS because otherwise the
  # standard directory is under `~/Library/Application Support/eza`
  export EZA_CONFIG_DIR=~/.config/eza
}

zinit ice \
  binary \
  atclone"source '${${(%):-%x}:h}/__eza_atclone_hook.zsh'" \
  atpull'%atclone' \
  depth=1 \
  wait \
  lucid \
  atinit'_safe_one_off_load __eza_init_hook' \
  nocompile \
  lbin'target/release/eza -> eza'
zinit light @eza-community/eza