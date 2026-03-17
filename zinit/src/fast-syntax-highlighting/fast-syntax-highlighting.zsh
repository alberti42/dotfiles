
# https://github.com/zdharma-continuum/fast-syntax-highlighting

typeset -g force_generation_fsh=false
typeset -gA FSH_BASE_THEME
FSH_BASE_THEME[dark]="default"
FSH_BASE_THEME[light]="default"

typeset -g FSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/fsh"
[[ -d "$FSH_CACHE_DIR" ]] || mkdir -p "$FSH_CACHE_DIR"

typeset -gA FSH_OVERLAY_FILES
FSH_OVERLAY_FILES[dark]="$DOTFILES_DIR/.config/fsh/overlay-dark.ini"
FSH_OVERLAY_FILES[light]="$DOTFILES_DIR/.config/fsh/overlay-light.ini"

typeset -gA FSH_CACHE_FILES
FSH_CACHE_FILES[dark]="$FSH_CACHE_DIR/theme_dark.zsh"
FSH_CACHE_FILES[light]="$FSH_CACHE_DIR/theme_light.zsh"

typeset -g FSH_THEMES_CACHE="$FSH_CACHE_DIR/themes.zsh"

function __fsh_atload_hook() {
  local regenerate_required=false

  # Save user-desired theme names before potentially overwriting with cached values
  local -A FSH_BASE_THEME_USER=( ${(kv)FSH_BASE_THEME} )
  if [[ -f "$FSH_THEMES_CACHE" ]]; then
    source "$FSH_THEMES_CACHE"
  fi
  local -A FSH_BASE_THEME_CACHED=( ${(kv)FSH_BASE_THEME} )

  if [[ "$force_generation_fsh" = (1|true|on|yes) ]]; then
    regenerate_required=true
  else
    [[ ! -f "${FSH_CACHE_FILES[dark]}"  || "$FSH_BASE_THEME_USER[dark]"  != "$FSH_BASE_THEME_CACHED[dark]"  ]] && regenerate_required=true
    [[ ! -f "${FSH_CACHE_FILES[light]}" || "$FSH_BASE_THEME_USER[light]" != "$FSH_BASE_THEME_CACHED[light]" ]] && regenerate_required=true
    [[ -f "${FSH_OVERLAY_FILES[dark]}"  && "${FSH_OVERLAY_FILES[dark]}"  -nt "${FSH_CACHE_FILES[dark]}"  ]] && regenerate_required=true
    [[ -f "${FSH_OVERLAY_FILES[light]}" && "${FSH_OVERLAY_FILES[light]}" -nt "${FSH_CACHE_FILES[light]}" ]] && regenerate_required=true
  fi

  if [[ "$regenerate_required" = true ]]; then
    {
      FSH_THEME_DARK=$FSH_BASE_THEME_USER[dark] \
      FSH_THEME_LIGHT=$FSH_BASE_THEME_USER[light] \
      source "${${(%):-%x}:a:h}/__generate_overlay_fsh.zsh"
    } always {
      unset FSH_THEME_DARK FSH_THEME_LIGHT
    }
  fi

  # zle_highlight is a native zsh parameter (https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html)
  # that controls how ZLE highlights buffer regions (paste/yank, active region, isearch, suffix).
  # zdharma-continuum/fast-syntax-highlighting reads zle_highlight to apply those styles, but never
  # writes it — so it cannot be configured via overlay.ini.
  # zle_highlight is set per appearance by zac (loaded at wait'0c', after this plugin at wait'0b').

  # Remove function for debug purposes
  if (( ${+functions[/fshdbg]} )); then
    unfunction /fshdbg
  fi
}

# Load syntax highlighting (plugin must be loaded after plugins issuing compdef)
zinit ice wait'0b' depth=1 light-mode lucid \
  blockf \
  atload'_safe_one_off_load __fsh_atload_hook; unset force_generation_fsh FSH_CACHE_DIR FSH_THEMES_CACHE FSH_BASE_THEME'

zinit light zdharma-continuum/fast-syntax-highlighting
