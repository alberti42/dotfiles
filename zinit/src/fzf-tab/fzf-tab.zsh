# https://github.com/Aloxaf/fzf-tab

function __fzf_tab_init_hook() {
  local script_path="${${(%):-%x}:a:h}"
  
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
  zstyle ':fzf-tab:complete:(kill|ps):*' fzf-preview "__zcompile_if_needed_and_source '${script_path}/__fzf_preview_kill.zsh' && __fzf_preview_kill \"\$word\" \"\$group\""

  # give a preview of commandline arguments when completing `killall`
  zstyle ':fzf-tab:complete:(killall):*' fzf-preview "__zcompile_if_needed_and_source '${script_path}/__fzf_preview_killall.zsh' && __fzf_preview_killall \"\$word\" \"\$group\""

  # no prview for options
  zstyle ':fzf-tab:complete:*:options' fzf-preview ''

  # underline the active group label
  zstyle ':fzf-tab:*' active-group-style underline,bold

  # no preview for subcommands
  # zstyle ':fzf-tab:complete:*:argument-1' fzf-preview ''

  # preview for files
  zstyle ":fzf-tab:complete:(ls|cd|cat|less|bat|vim|nvim|cp|mv|rm|e|emacs|nano|subl|rsubl):*" fzf-preview "__zcompile_if_needed_and_source '${script_path}/__fzf_preview_file.zsh' && __fzf_preview_file \"\$realpath\""
  # zstyle ":fzf-tab:complete:*:*" fzf-preview "__zcompile_if_needed_and_source '${script_path}/__fzf_preview_file.zsh' && __fzf_preview_file \$realpath"

  # Force fzf-tab to use FZF_DEFAULT_OPTS; fzf-tab does not follow FZF_DEFAULT_OPTS by default
  # NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
  zstyle ':fzf-tab:*' use-fzf-default-opts yes
  
  zstyle ":fzf-tab:*" fzf-flags \
    --ansi \
    --bind=tab:accept \
    --height="70%" \
    --preview-window="right:60%" \
    --padding="0,1,0,0" \
    --min-height=20
}

# Add fzf support to zsh; check https://thevaluable.dev/practical-guide-fzf-example/
# It requires zicompinit; zicompinit; so it must be called after fast-syntax-highlighting
zinit ice wait'0a' light-mode lucid \
  atclone"source '${${(%):-%x}:a:h}/__fzf_tab_atclone_hook.zsh'" \
  atinit'_safe_one_off_load __fzf_tab_init_hook' \
  ver'integrated' \
  id-as'Aloxaf/fzf-tab'

zinit light alberti42/fzf-tab-fork
# zinit light Aloxaf/fzf-tab
# depth 1
# latest-release
# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
