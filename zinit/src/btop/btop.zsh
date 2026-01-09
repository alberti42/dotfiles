# https://github.com/aristocratos/btop

() {
  # This anonymous function isolates variables and helper functions.
  local -a _ices
  _ices+=(
    nocompile        # There are no zsh scripts to be z-compiled
    lucid            # Show output from hooks.
    null             # Don't source any files.
    wait'0a'         # Run in the background.
  )
  
  if [[ $OSTYPE == 'darwin'* ]]; then
    # On macOS, build from source using the null repository pattern.
    _ices+=(
      atclone'
        command env QUIET=true CXXFLAGS="-Wno-deprecated-declarations -Wno-unused-command-line-argument -Wno-unused-private-field" \
        command make -j${(n)NPROCS:-8} && command make install PREFIX="$ZPFX"
      '
      atpull'%atclone'
      latest-release   # Select the latest release (this is not automatic for source code).
    )
  else
    # On Linux, the gh-r method remains the simplest choice.
  fi
  zinit ice "${_ices[@]}"
  zinit light aristocratos/btop
}
