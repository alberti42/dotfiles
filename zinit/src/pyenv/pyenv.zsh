# https://github.com/pyenv/pyenv

# 1. Install the `ccache` binary from its official GitHub: https://github.com/ccache/ccache
#    `from'gh-r'` tells zinit to look for release assets.
#    `as'command'` automatically adds the executable to your $PATH.
#    `bpick` selects the correct file for macOS from the release assets.
zinit ice wait from'gh-r' as'command' lbin'!ccache -> ccache' lucid
zinit light ccache/ccache

# 2. Pyenv plugins
zinit wait depth=1 light-mode lucid as'null' nocompletions nocompile for \
  id-as'pyenv/doctor' pyenv/pyenv-doctor \
  id-as'pyenv/update' pyenv/pyenv-update \
  id-as'pyenv/pip-migrate' pyenv/pyenv-pip-migrate \
    atload"export PYENV_VIRTUALENV_FAST_SCAN='${${(%):-%x}:a:h}/scan_virtualenv_full.bash'" \
    atpull'%atclone' \
    atclone"python3 '${${(%):-%x}:a:h}/inject_pyenv_virtualenv_fast_scan.py' ./bin/pyenv-virtualenvs" \
    id-as:'pyenv/virtualenv' pyenv/pyenv-virtualenv \
  id-as'pyenv/ccache' pyenv/pyenv-ccache

# 3. Pyenv manager
zinit wait depth'1' light-mode lucid binary \
  atclone"source '${${(%):-%x}:a:h}/__pyenv_atclone_hook.zsh'" \
  atpull"%atclone" \
  atload"__zcompile_if_needed_and_source '${${(%):-%x}:a:h}/zi_pyenv_init.zsh'" \
  lbin'!bin/pyenv -> pyenv' \
  for @pyenv/pyenv

# 4. Pyenv rehash
# Installs shims for all Python binaries known to pyenv (i.e., ~/.pyenv/versions/*/bin/*).
# We must run this command after we install a new version of Python, or install a package
# that provides binaries. To be on the safe side, we launch it at logon, but delayed
# zinit wait'1' id-as'pyenv/rehash' atload'command pyenv rehash' light-mode lucid for zdharma-continuum/null