# https://github.com/pyenv/pyenv

# Pyenv manager
zinit wait depth=1 light-mode lucid as'null' nocompletions nocompile for \
  id-as:'pyenv/doctor' pyenv/pyenv-doctor \
  id-as:'pyenv/update' pyenv/pyenv-update \
  id-as:'pyenv/pip-migrate' pyenv/pyenv-pip-migrate \
  id-as:'pyenv/virtualenv' pyenv/pyenv-virtualenv \
  id-as:'pyenv/ccache' pyenv/pyenv-ccache

zinit wait depth=1 light-mode lucid as'null' nocompletions nocompile for \
  id-as:'pyenv/virtualenv' configure'' pyenv/pyenv-virtualenv

# Pyenv manager
zinit ice wait depth=1 light-mode lucid binary \
  atinit'export PYENV_ROOT="$HOME/.pyenv"' \
  atclone"source '${${(%):-%x}:h}/__pyenv_atclone_hook.zsh'" \
  atpull"%atclone" \
  completions \
  sbin'!libexec/pyenv -> pyenv' \
  compile:'zi_pyenv_init.zsh' \
  src"zi_pyenv_init.zsh" \
  nocompile'!'
zinit light @pyenv/pyenv
