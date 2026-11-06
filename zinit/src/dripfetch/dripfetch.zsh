# https://github.com/a-shygun/dripfetch
# Config: $DOTFILES_DIR/.config/dripfetch/config.yaml, colors switched by zac/zac-io-cmd.zsh.
# Installed from source into a uv venv: the release binary is a PyInstaller --onefile
# build that unpacks itself on every run (1.6 s per start, 0.08 s from the venv).
# Pinned to the commit of v0.5.0, which was reviewed for malicious code on 2026-11-02.
# To upgrade, review the new commit first, then change ver and run `zinit update a-shygun/dripfetch`.

zinit ice \
    null \
    wait'0b' \
    lucid \
    nocompile \
    ver'eb98c7b25b36858e8fe8f38c807638ca2abe688e' \
    atclone'command uv venv -q --allow-existing .venv && command uv pip install -q --python .venv/bin/python --reinstall-package dripfetch .' \
    atpull'%atclone' \
    lbin'.venv/bin/dripfetch -> dripfetch'
zinit light @a-shygun/dripfetch
