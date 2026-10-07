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

  # We use zicompdef because this function is executed at the
  # initialization stage, where compdef is not redirected yet by
  # zinit.
  zicompdef l=eza
  zicompdef ll=eza
  zicompdef llm=eza
  zicompdef lls=eza
  zicompdef la=eza
  zicompdef lx=eza
  zicompdef tree=eza

  # Needed under macOS because otherwise the
  # standard directory is under `~/Library/Application Support/eza`
  export EZA_CONFIG_DIR=~/.config/eza
}

zinit ice \
    null \
    depth=1 \
    wait'0b' \
    lucid \
    atinit'_safe_one_off_load __eza_init_hook' \
    nocompile \
    latest-release \
    completions \
    atclone"source '${${(%):-%x}:a:h}/__eza_atclone_hook.zsh'" \
    atpull'%atclone' \
    lbin'target/release/eza -> eza'
zinit light @eza-community/eza
