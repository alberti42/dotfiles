# https://github.com/Aloxaf/fzf-tab

__fzf_tab_init_hook() {
  # disable sort when completing `git checkout`
  zstyle ":completion:*:git-checkout:*" sort false
  
  # force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
  zstyle ':completion:*' menu no

  # set descriptions format to enable group support
  # Note: don't use escape sequences (like '%F{red}%d%f') here; fzf-tab will ignore them
  zstyle ':completion:*:descriptions' format '[%d]'
  
  # disable sort when completing `git checkout`
  zstyle ':completion:*:git-checkout:*' sort false

  # NOTE: Check https://github.com/Aloxaf/fzf-tab/wiki/Configuration#zstyle for customization of zstyle
  
  # switch group using `<` and `>`
  zstyle ':fzf-tab:*' switch-group '<' '>'

  # give a preview of commandline arguments when completing `kill`
  zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags '--preview-window=down:3:wrap'
  zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview '
    if [[ $group == "[process ID]" ]]; then
      echo -n "Command: "
      if [[ $OSTYPE = darwin* ]]; then
        ps -p "$word" -o command=
      else
        ps --pid=$word -o cmd --no-headers -w -w && false
      fi
    fi
  '
  
  # no prview for options
  zstyle ':fzf-tab:complete:*:options' fzf-preview ''

  # no preview for subcommands
  # zstyle ':fzf-tab:complete:*:argument-1' fzf-preview ''
  
  # preview for files
  zstyle ":fzf-tab:complete:*:*" fzf-preview '
    if [[ -d "$realpath" ]]; then
      tree -C -L 3 "$realpath"
    elif [[ -f "$realpath" ]]; then
      if $(grep -qI . "$realpath"); then
        bat -p --color=always "$realpath"
      else
        echo "Realpath: $realpath"
        # Use gstat for Linux; fallback to stat for macOS or BSD
        local gprefix
        local -a stat_opts
        local arch=$(uname -s)
        if [[ $OSTYPE = darwin* ]]; then
          # Darwin / FreeBSD version
          command -v gstat &>/dev/null && gprefix=g
          if [[ -z $gprefix ]]; then
              stat_opts=(
                "-f"
                "File: %N\nLocation: %d:%i\nMode: %Sp (%Mp%Lp)\nLinks: %l\nOwner: %Su/%Sg\nSize: %z (%b blocks)\nChanged: %Sc\nModified: %Sm\nAccessed: %Sa"
              )
          fi
        fi
        # Linux or Darwin with GNU support
        if [[ -z $stat_opts ]]; then
          stat_opts=(
            "-c"
            "File: %N\nType: %F\nLocation: %d:%i\nMode: %A (%a)\nLinks: %h\nOwner: %U/%G\nSize: %s (%b blocks)\nChanged: %z\nModified: %y\nAccessed: %x"
          )
        fi

        local stat_cmd="${gprefix}stat"
        echo $($stat_cmd "$stat_opts[@]" "$realpath")
      fi
    fi'

  # Custom fzf flags. Note: fzf-tab does not follow FZF_DEFAULT_OPTS by default
  zstyle ":fzf-tab:*" fzf-flags \
    "--bind=tab:accept" \
    "--height=70%" \
    "--preview-window=right:60%" \
    "--padding=0,1,0,0" \
    "--min-height=20" \
    "--color=info:#b36198,prompt:#0050ff,pointer:#ffffff" \
    "--color=hl:#ffffff" \
    "--color=hl+:#ffffff"
}

# Enable preview only for files and directories
# zstyle ':fzf-tab:complete:*:(files|directories)' fzf-preview 'ls --color=auto -l $realpath'

# Add fzf support to zsh; check https://thevaluable.dev/practical-guide-fzf-example/
# It requires zicompinit; zicompinit; so it must be called after fast-syntax-highlighting
zinit ice depth=1 wait light-mode lucid \
  atclone"source '${${(%):-%x}:h}/__fzf_tab_atclone_hook.zsh'" \
  atinit'_safe_one_off_load __fzf_tab_init_hook'
zinit light Aloxaf/fzf-tab
