# https://github.com/Aloxaf/fzf-tab

function __fzf_tab_init_hook() {
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
  local script_path="${(%):-%x}"
  zstyle ":fzf-tab:complete:*:*" fzf-preview "__zcompile_if_needed_and_source '${script_path:h}/__fzf_file_preview.zsh' && __fzf_file_preview \$realpath"

  # Force fzf-tab to use FZF_DEFAULT_OPTS; fzf-tab does not follow FZF_DEFAULT_OPTS by default
  # NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
  zstyle ':fzf-tab:*' use-fzf-default-opts yes
  
  zstyle ":fzf-tab:*" fzf-flags \
    "--bind=tab:accept" \
    "--height=70%" \
    "--preview-window=right:60%" \
    "--padding=0,1,0,0" \
    "--min-height=20"
}

# Enable preview only for files and directories
# zstyle ':fzf-tab:complete:*:(files|directories)' fzf-preview 'ls --color=auto -l $realpath'

# Add fzf support to zsh; check https://thevaluable.dev/practical-guide-fzf-example/
# It requires zicompinit; zicompinit; so it must be called after fast-syntax-highlighting
zinit ice depth=1 wait light-mode lucid \
  atclone"source '${${(%):-%x}:h}/__fzf_tab_atclone_hook.zsh'" \
  atinit'_safe_one_off_load __fzf_tab_init_hook' \
  id-as'Aloxaf/fzf-tab'
zinit light Aloxaf/fzf-tab
