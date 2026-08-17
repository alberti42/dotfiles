# https://github.com/tmux/tmux

zinit ice from"gh-r" \
  atclone'
    cd tmux-*/ || exit 1
    local _brew _ncurses_pc rc

    # Dependency search paths are macOS-only: there we rely on Homebrew. On
    # Linux/BSD the system ncurses (6.x) and libevent are already modern and on
    # the default search paths, so we configure plainly and touch no brew.
    #
    # macOS needs extra care for ncurses: the system copy is a frozen 5.7
    # (libncurses.5.4.dylib), and tmux gates the OSC 8 hyperlink output
    # capability (Hls) behind `#if NCURSES_VERSION > 5.8` (see tty-features.c) —
    # so building against it silently drops hyperlink passthrough. Homebrew
    # ncurses (6.x) is keg-only, so we point pkg-config at its prefix; configure
    # then matches it via its `ncurses` module (Homebrew ships ncurses.pc) and
    # compiles Hls in.
    if [[ "$OSTYPE" == darwin* ]]; then
      _brew="$(brew --prefix)"
      export CPPFLAGS="-I$_brew/include${CPPFLAGS:+ $CPPFLAGS}"
      export LDFLAGS="-L$_brew/lib${LDFLAGS:+ $LDFLAGS}"
      _ncurses_pc="$(brew --prefix ncurses 2>/dev/null)/lib/pkgconfig"
      [[ -d "$_ncurses_pc" ]] && \
        export PKG_CONFIG_PATH="$_ncurses_pc${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    fi

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
