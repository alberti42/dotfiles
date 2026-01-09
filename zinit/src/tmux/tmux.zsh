# https://github.com/tmux/tmux

zinit ice from"gh-r" \
  atclone'
    cd tmux-*/ && \
    CPPFLAGS="-I$(brew --prefix)/include" LDFLAGS="-L$(brew --prefix)/lib" \
    ./configure -quiet --prefix="$ZPFX" --enable-utf8proc && \
    {
      make -s 2>&1 | tee build.log | grep -E --line-buffered -i "error:|ld:|fatal" || true
      rc=$pipestatus[1]   # exit status of the *first* command in the pipeline (make)
      if (( rc != 0 )); then
        echo "Build failed (rc=$rc). See build.log"
        exit $rc
      fi
    } && \
    make -s install
  ' \
  null nocompletions lucid
zinit light tmux/tmux

# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
