# https://github.com/sharkdp/vivid

typeset -g ls_color_theme="snazzy"
typeset -g force_generation_color_scheme=false
typeset -g src_ls_colors_file="$ZSH_CACHE_DIR/src_ls_colors.zsh" # used for loading LS_COLORS environment variable
typeset -g ls_colors_file="$ZSH_CACHE_DIR/ls_colors" # used for tmux-fzf-links plugin

__my_vivid_load_hook() {
  # Check if we need to reload
  if [[ "$force_generation_color_scheme" = (1|true|on|yes) || ! -f "$ls_colors_file" ]]; then
    source "${${(%):-%x}:h}/__generate_ls_colors.zsh"
  fi
  source "$src_ls_colors_file"
}

zinit ice depth=1 wait lucid \
  from:'gh-r' \
  lbin:'vivid -> vivid' \
  atload'_safe_one_off_load __my_vivid_load_hook; unset ls_color_theme force_generation_color_scheme ls_colors_file'
zinit light @sharkdp/vivid
