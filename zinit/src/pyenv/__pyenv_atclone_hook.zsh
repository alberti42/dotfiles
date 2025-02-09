# Andrea Alberti, 2024

function __pyenv_atclone_hook() {
  # We do not need `pyenv virtualenv-init -` even though it is recommended
  # in the official instructions. It is only needed if we want to modify the prompt
  # to recognize the virtual environment. Typically, recognition of the venv is
  # already done by shell prompt like oh-my-zsh prompts or powerlevel10k.
  local PYENV_ROOT="$HOME/.pyenv" &&
  rm -rf $PYENV_ROOT/plugins &&
  mkdir -p $PYENV_ROOT/plugins &&
  ln -s $ZINIT[PLUGINS_DIR]/pyenv---doctor $PYENV_ROOT/plugins/pyenv-doctor &&
  ln -s $ZINIT[PLUGINS_DIR]/pyenv---update $PYENV_ROOT/plugins/pyenv-update &&
  ln -s $ZINIT[PLUGINS_DIR]/pyenv---pip-migrate $PYENV_ROOT/plugins/pyenv-pip-migrate &&
  ln -s $ZINIT[PLUGINS_DIR]/pyenv---virtualenv $PYENV_ROOT/plugins/pyenv-virtualenv &&
  ln -s $ZINIT[PLUGINS_DIR]/pyenv---ccache $PYENV_ROOT/plugins/pyenv-ccache &&
  env PYENV_ROOT=$PYENV_ROOT ./libexec/pyenv init - > zi_pyenv_init.zsh &&
  cp -vf $DOTFILES_DIR/zinit/src/pyenv/_pyenv . &&
  cp -vf man/man1/pyenv.1 $ZINIT[MAN_DIR]/man1/
}
_safe_one_off_load __pyenv_atclone_hook
