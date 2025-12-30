# https://github.com/tmux/tmux

zinit ice from"gh-r" \
    atclone'
        # Change into the extracted, versioned subdirectory
        cd tmux-*/ && \
        CPPFLAGS="-I$(brew --prefix)/include" LDFLAGS="-L$(brew --prefix)/lib" \
        ./configure --prefix="$ZPFX" --enable-utf8proc && \
        make && make install
    ' \
    null nocompletions lucid
zinit light tmux/tmux
