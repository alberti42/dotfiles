#!/hint/zsh

function __my_dark_mode_setter() {
  local is_dark=$1  
  
  if (( is_dark )); then
    # fzf plugin
    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS_CATPPUCCIN[macchiato]"

    # zsh-opencode-tab plugin
    _zsh_opencode_tab[spinner.bg_hex]="#24273A"
  else
    # fzf plugin
    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS_CATPPUCCIN[frappe]"

    # zsh-opencode-tab plugin
    _zsh_opencode_tab[spinner.bg_hex]="#303446"
  fi
}

() {
  local __local_plugin_path="$DOTFILES_DIR/oh-my-zsh/custom/plugins"

  zinit lucid wait light-mode for \
    wait'0c' atinit:"export ZAC_CALLBACK_FNC=__my_dark_mode_setter" $__local_plugin_path/zsh-appearance-control
}