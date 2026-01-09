# https://github.com/jonas/tig

zinit ice \
  binary \
  depth=1 \
  wait'0a' \
  lucid \
  dl"https://github.com/alberti42/fork-tig/releases/download/latest-man-pages/tig.1 -> $ZINIT[MAN_DIR]/man1/tig.1;
  https://github.com/alberti42/fork-tig/releases/download/latest-man-pages/tigmanual.7 -> $ZINIT[MAN_DIR]/man7/tigmanual.7;
  https://github.com/alberti42/fork-tig/releases/download/latest-man-pages/tigrc.5 -> $ZINIT[MAN_DIR]/man5/tigrc.5;" \
  make \
  id-as'jonas/tig' \
  lbin'src/tig -> tig' \
  nocompile
zinit light @alberti42/fork-tig
