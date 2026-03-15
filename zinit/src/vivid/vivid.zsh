# https://github.com/sharkdp/vivid

typeset -g force_generation_color_scheme=false
typeset -gA LS_COLORS_THEME
LS_COLORS_THEME[dark]="snazzy"
LS_COLORS_THEME[light]="ayu"

typeset -g VIVID_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/vivid"
[[ -d "$VIVID_CACHE_DIR" ]] || mkdir -p "$VIVID_CACHE_DIR"

typeset -gA LS_COLORS_FILES
LS_COLORS_FILES[dark]="$VIVID_CACHE_DIR/ls_colors_dark.zsh"
LS_COLORS_FILES[light]="$VIVID_CACHE_DIR/ls_colors_light.zsh"

typeset -g LS_COLORS_THEMES_CACHE="$VIVID_CACHE_DIR/themes.zsh"

__my_vivid_load_hook() {
  local regenerate_required=false

  # Load cached theme names
  local -A LS_COLOR_THEME_USER=( ${(kv)LS_COLORS_THEME} )
  if [[ -f "$LS_COLORS_THEMES_CACHE" ]]; then
    source "$LS_COLORS_THEMES_CACHE"
  fi
  local -A LS_COLOR_THEME_CACHED=( ${(kv)LS_COLORS_THEME} )

  if [[ "$force_generation_color_scheme" = (1|true|on|yes) ]]; then
    regenerate_required=true
  else
    [[ ! -f "${LS_COLORS_FILES[dark]}" || "$LS_COLOR_THEME_USER[dark]" != "$LS_COLOR_THEME_CACHED[dark]" ]] && regenerate_required=true
    [[ ! -f "${LS_COLORS_FILES[light]}" || "$LS_COLOR_THEME_USER[light]" != "$LS_COLOR_THEME_CACHED[light]" ]] && regenerate_required=true
  fi

  if [[ "$regenerate_required" = true ]]; then
    {
      THEME_DARK=$LS_COLOR_THEME_USER[dark] \
      THEME_LIGHT=$LS_COLOR_THEME_USER[light] \
      source "${${(%):-%x}:a:h}/__generate_ls_colors.zsh"
    } always {
      unset THEME_DARK THEME_LIGHT
    }
  fi
}

zinit ice depth=1 wait'0b' lucid \
  from:'gh-r' \
  extract'!' \
  lbin:'vivid -> vivid' \
  atload'_safe_one_off_load __my_vivid_load_hook; unset force_generation_color_scheme VIVID_CACHE_DIR LS_COLORS_THEMES_CACHE LS_COLORS_THEME'
zinit light @sharkdp/vivid
