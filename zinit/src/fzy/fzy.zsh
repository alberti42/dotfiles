# fzy.zsh

# https://github.com/jhawthorn/fzy
zinit ice \
  binary \
  depth=1 \
  lucid \
  make'all' \
  atclone'cp -vf fzy.1 $ZINIT[MAN_DIR]/man1/' \
  atpull"%atclone" \
  lbin'fzy -> fzy'
zinit light @jhawthorn/fzy
