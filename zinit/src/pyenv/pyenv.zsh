# https://github.com/pyenv/pyenv

# 1. Install the `ccache` binary from its official GitHub: https://github.com/ccache/ccache
#    `from'gh-r'` tells zinit to look for release assets.
#    `as'command'` automatically adds the executable to your $PATH.
#    `bpick` selects the correct file for macOS from the release assets.
zinit ice wait from'gh-r' as'command' lbin'!ccache -> ccache' lucid
zinit light ccache/ccache

# 2. Pyenv plugins
zinit wait'1' depth=1 light-mode lucid as'null' nocompletions nocompile for \
  id-as:'pyenv/doctor' pyenv/pyenv-doctor \
  id-as:'pyenv/update' pyenv/pyenv-update \
  id-as:'pyenv/pip-migrate' pyenv/pyenv-pip-migrate \
  id-as:'pyenv/virtualenv' pyenv/pyenv-virtualenv \
  id-as:'pyenv/ccache' pyenv/pyenv-ccache

# 3. Pyenv manager
zinit wait'1' depth'1' light-mode lucid binary \
  atinit"export PYENV_ROOT='$HOME/.pyenv'" \
  atclone"source '${${(%):-%x}:h}/__pyenv_atclone_hook.zsh'" \
  atpull"%atclone" \
  lbin'!bin/pyenv -> pyenv' \
  src"zi_pyenv_init.zsh" \
  for @pyenv/pyenv
