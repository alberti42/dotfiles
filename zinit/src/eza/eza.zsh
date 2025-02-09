# https://github.com/eza-community/eza

zinit ice \
  binary \
  atclone"source '${${(%):-%x}:h}/__eza_atclone_hook.zsh'" \
  atpull'%atclone' \
  depth=1 \
  wait \
  lucid \
  nocompile \
  lbin'target/release/eza -> eza'
zinit light @eza-community/eza
