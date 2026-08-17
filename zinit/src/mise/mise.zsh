# https://github.com/jdx/mise
#
# Polyglot runtime / tool-version manager (asdf-compatible). Added as
# the long-term replacement for pyenv — e.g. `mise use --global
# python@3.12`. Until the migration is complete pyenv and mise
# coexist; see the migration note in .zshrc.
#
# We deliberately pull the `.tar.xz` release asset: macOS
# `tar`/libarchive unpacks xz natively (and `xz` is installed
# anyway). Pinning the extension via `bpick` also disambiguates the
# tarball from the bare `mise-*-macos-<arch>` raw-binary asset that
# would otherwise compete with it during gh-r auto-detection.

# mise's generated zsh completions are *dynamic*: at runtime they
# shell out to the `usage` CLI (https://usage.jdx.dev), which is NOT
# bundled with mise.
zinit ice binary wait'0b' lucid from'gh-r' \
      bpick'*universal-apple-darwin.tar.gz' \
      lbin'!usage -> usage' \
      cp"usage.1 -> $ZINIT[MAN_DIR]/man1/usage.1"
zinit light @jdx/usage

zinit ice binary wait'0b' lucid from'gh-r' \
      bpick"*macos-${CPUTYPE}.tar.xz" \
      lbin'!*/bin/mise -> mise' \
      cp"*/man/man1/mise.1 -> $ZINIT[MAN_DIR]/man1/mise.1" \
      atclone"*/bin/mise completion zsh > _mise" \
      completion \
      atpull'%atclone' \
      atload'eval "$(mise activate zsh)"'

zinit light @jdx/mise
