#!/hint/zsh

function __my_dark_mode_setter() {
  local is_dark=$1  
  
  # Prevent execution if called without argument
  [[ ! -z "$is_dark" ]] || return
  
  if (( is_dark )); then
    # Keep track of the background color
    local BACKGROUND_COLOR="#303446"

    # LS_COLORS
    source "$LS_COLORS_FILES[dark]"

    # fzf plugin
    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS_CATPPUCCIN[frappe]"

    # bat
    export BAT_CONFIG_PATH="$DOTFILES_DIR/.config/bat/config-dark"
  else
    # Keep track of the background color
    local BACKGROUND_COLOR="#EFF1F5"

    # LS_COLORS
    source "$LS_COLORS_FILES[light]"

    # fzf plugin
    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS_CATPPUCCIN[latte]"

    # bat
    export BAT_CONFIG_PATH="$DOTFILES_DIR/.config/bat/config-light"
  fi

  # zsh-opencode-tab plugin
  if (( ${+_zsh_opencode_tab[spinner.bg_hex]} )); then
    _zsh_opencode_tab[spinner.bg_hex]=$BACKGROUND_COLOR
  else
    export Z_OC_TAB_SPINNER_BG_HEX=$BACKGROUND_COLOR
  fi

  # Check if LS_COLORS is defined
  if (( ${+LS_COLORS} )); then
    # General completion colors
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

    # Default list colors + highlight the matched substring/item with gray-blue background, normal foreground
    # This configuration is only relevant for `menu select` and not relevant for fzf-tab
    zstyle ':completion:*:default' list-colors \
      "${(s.:.)LS_COLORS}" \
      'ma=48;2;60;70;90'
  else
    [[ ${ZINIT[MUTE_WARNINGS]} != (1|true|on|yes) && $quiet != -q ]] && \
      +zi-log "{u-warn}Warning{b-warn}: zsh-completions cannot use LS_COLORS."
  fi
}

() {
  local __local_plugin_path="$DOTFILES_DIR/oh-my-zsh/custom/plugins"

  zinit lucid wait light-mode for \
      wait'0c' atinit"export ZAC_CALLBACK_FNC=__my_dark_mode_setter" \
      atload"zac sync && __my_dark_mode_setter $REPLY" \
      $__local_plugin_path/zsh-appearance-control
}