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

  # We use atinit'!...' whihc runs in the loading stage after zinit
  # redirected compdef to just do book-keeping and delay execution of
  # compdef to the end when compinit finally runs just one time only.
  compdef l=eza
  compdef ll=eza
  compdef llm=eza
  compdef lls=eza
  compdef la=eza
  compdef lx=eza
  compdef tree=eza

  # Needed under macOS because otherwise the
  # standard directory is under `~/Library/Application Support/eza`
  export EZA_CONFIG_DIR=~/.config/eza
}

zinit ice \
    null \
    depth=1 \
    wait'0b' \
    lucid \
    atinit'!_safe_one_off_load __eza_init_hook' \
    nocompile \
    latest-release \
    completions \
    atclone"source '${${(%):-%x}:a:h}/__eza_atclone_hook.zsh'" \
    atpull'%atclone' \
    lbin'target/release/eza -> eza'
zinit light @eza-community/eza
