# https://github.com/sharkdp/fd
zinit ice \
  binary \
  depth=1 \
  lucid \
  from'gh-r' \
  atpull"%atclone" \
  atclone'cp -vf */fd.1 $ZINIT[MAN_DIR]/man1/' \
  lbin'fd(.exe|) -> fd'
zinit light @sharkdp/fd

# https://github.com/sharkdp/bat
zinit ice \
  binary \
  depth=1 \
  lucid \
  from'gh-r' \
  atpull'%atclone' \
  atclone'
    local file &&
    cp -vf */bat.1 $ZPFX/man/man1/bat.1 \
    && for file in */autocomplete/bat.zsh; do; cp -vf "$file" "${file%bat.zsh}_bat"; done &&
    if [[ ! -d "$XDG_CONFIG_HOME/bat" ]]; then
      +zi-log "Installing bat configuration..." &&
      ln -s $DOTFILES_DIR/.config/bat "$XDG_CONFIG_HOME/bat" &&
    fi &&
    if [[ ! $(realpath ~/.config/bat) = $(realpath $DOTFILES_DIR/.config/bat) ]]; then
      +zi-log "{u-warn}Warning{b-warn}: sharkdp/brat: folder "$XDG_CONFIG_HOME/bat" is not a symlink to the corresponding directory under \$DOTFILES_DIR${ZINIT[col-rst]}"
    fi &&
    bat-*/bat cache --build
  ' \
  lbin'bat(.exe|) -> bat'
zinit light @sharkdp/bat

# https://github.com/sharkdp/hexyl
zinit ice \
  binary \
  depth=1 \
  lucid \
  from'gh-r' \
  atpull'%atclone' \
  atclone'cp -vf */hexyl.1  $ZINIT[MAN_DIR]/man1/' \
  lbin'hexyl(.exe|) -> hexyl'
zinit light @sharkdp/hexyl

# https://github.com/sharkdp/hyperfine
zinit ice \
  binary \
  depth=1 \
  lucid \
  from'gh-r' \
  atpull'%atclone' \
  atclone'cp -vf */hyperfine.1 $ZINIT[MAN_DIR]/man1/' \
  lbin'hyperfine(.exe|) -> hyperfine'
zinit light @sharkdp/hyperfine
