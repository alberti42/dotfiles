# https://github.com/a-shygun/dripfetch
# Config: $DOTFILES_DIR/.config/dripfetch/config.yaml, colors switched by zac/zac-io-cmd.zsh.
# Installed from source into a uv venv: the release binary is a PyInstaller --onefile
# build that unpacks itself on every run (1.6 s per start, 0.08 s from the venv).

zinit ice \
    null \
    wait'0b' \
    lucid \
    nocompile \
    latest-release \
    atclone'command uv venv -q --allow-existing .venv && command uv pip install -q --python .venv/bin/python --reinstall-package dripfetch .' \
    atpull'%atclone' \
    lbin'.venv/bin/dripfetch -> dripfetch'
zinit light @a-shygun/dripfetch
