# https://github.com/jqlang/jq

# Install jq — a lightweight command-line JSON processor akin to sed,awk,grep for JSON data.

zinit ice binary wait lucid from"gh" \
    lbin'!jq -> jq' \
    depth=1 \
    atclone'
      # instructions from https://github.com/jqlang/jq
      git submodule update --init &&   # if building from git to get oniguruma
      autoreconf -i               &&   # if building from git
      ./configure --with-oniguruma=builtin --prefix=$ZPFX &&
      make clean                  &&   # if upgrading from a version previously built from source
      make -j8 &&
      make check
    ' \
    atpull'%atclone'
zinit light @jqlang/jq
