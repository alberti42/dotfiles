# https://github.com/aristocratos/btop

() {
  # This anonymous function isolates variables and helper functions.
  local -a _ices

  # This build hook is now smarter. It checks the installed version
  # against the latest remote tag and ensures the repo is on the correct commit.
  function __btop_build_hook() {
    +zi-log "{i} {pname}btop{rst}: Checking for updates..."
    local latest_tag installed_tag current_commit target_commit
    # Store the tag file in zinit's metadata directory for the plugin.
    local tag_file="._zinit/tag"

    # 1. Get the latest tag from the remote repository.
    latest_tag=$(command git ls-remote --tags --sort=-v:refname | head -n1 | cut -f2 | sed "s|refs/tags/||;s/\^{}//")
    if [[ -z "$latest_tag" ]]; then
      +zi-log "{e} {pname}btop{rst}: Could not determine the latest tag from remote."
      return 1
    fi

    # 2. Get the currently installed tag from our local file, if it exists.
    if [[ -f "$tag_file" ]]; then
      installed_tag=$(<"$tag_file")
    fi

    # 3. Compare tags and decide whether to build or just sync the repo state.
    if [[ "$latest_tag" == "$installed_tag" ]]; then
      +zi-log "{i} {pname}btop{rst}: Version {version}$latest_tag{rst} is already installed."
      # CONSISTENCY CHECK: Ensure the repo is checked out at the correct tag.
      current_commit=$(command git rev-parse --quiet HEAD)
      target_commit=$(command git rev-parse --quiet "$latest_tag^{}") # Get commit hash of the tag

      if [[ "$current_commit" != "$target_commit" ]]; then
        +zi-log "{m} {pname}btop{rst}: Repository is on a different commit. Checking out tag {version}$latest_tag{rst} for consistency..."
        command git -c advice.detachedHead=false checkout "$latest_tag"
      else
        +zi-log "{m} {pname}btop{rst}: Repository is already on the correct commit. Nothing to do."
      fi
      return 0 # Success, no build needed.
    fi

    # 4. If tags differ, a full build and install is needed.
    +zi-log "{m} {pname}btop{rst}: Checking out tag: {version}$latest_tag{rst}"
    if command git -c advice.detachedHead=false checkout "$latest_tag" && \
       +zi-log "{m} {pname}btop{rst}: Building..." && \
       command make -j${(n)NPROCS:-8} && \
       +zi-log "{m} {pname}btop{rst}: Installing to {file}$ZPFX{rst}..." && \
       command make install PREFIX="$ZPFX"; then
      # 5. On successful install, write the new tag to the file.
      # This is critical for the logic to work on the next run.
      echo "$latest_tag" > "$tag_file"
      +zi-log "{happy}btop: Successfully installed version {version}'$latest_tag'{happy}.{rst}"
    else
      +zi-log "{e} {pname}btop{rst}: Build or install failed."
      return 1
    fi
  }

  # These ices are common to both installation methods.
  _ices+=(
    lucid    # Show output from atclone/atpull hooks.
    null     # Don't source any files, as this is a binary.
    wait'0'  # Load in the background immediately.
  )

  if [[ $OSTYPE == 'darwin'* ]]; then
    # On macOS, we build from source.
    _ices+=(
      from'gh'
      # Run our smart build hook on the first install.
      atclone'__btop_build_hook'
      # For updates (`zinit update`), reuse the same logic as atclone.
      atpull'%atclone'
    )
  else
    # On Linux and other systems, we download a pre-compiled binary.
    _ices+=(
      from'gh-r'
      link'btop'  # Create a symlink for the `btop` binary in $ZPFX/bin
    )
  fi

  # Apply all the collected ices and load the plugin.
  zinit ice "${_ices[@]}"
  zinit light aristocratos/btop
}
