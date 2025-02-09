# https://doc.rust-lang.org/cargo/getting-started/installation.html

# We do not install rustc here; we let zshenv handle its installation; we only manage updates of rustc
zinit ice \
    id-as"rust/rust" \
    lucid \
    run-atpull \
    atpull'rustup update' \
    atclone'' \
    nocompile
zinit load zdharma-continuum/null
