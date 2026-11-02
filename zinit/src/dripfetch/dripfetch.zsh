# https://github.com/a-shygun/dripfetch
# Config: $DOTFILES_DIR/.config/dripfetch/config.yaml, colors switched by zac/zac-io-cmd.zsh.
# bpick: the release also ships the sdist dripfetch-<ver>.tar.gz and .deb packages.

zinit ice \
    null \
    wait'0b' \
    lucid \
    from'gh-r' \
    nocompile \
    bpick'dripfetch_*.tar.gz' \
    lbin'dripfetch -> dripfetch'
zinit light @a-shygun/dripfetch
