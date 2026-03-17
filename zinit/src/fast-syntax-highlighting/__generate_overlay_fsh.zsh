#!/hint/zsh

function __generate_fsh_theme() {
  local mode="$1"
  local base_theme overlay_ini target_file

  if [[ "$mode" = "dark" ]]; then
    base_theme="$FSH_THEME_DARK"
    overlay_ini="${FSH_OVERLAY_FILES[dark]}"
    target_file="${FSH_CACHE_FILES[dark]}"
  else
    base_theme="$FSH_THEME_LIGHT"
    overlay_ini="${FSH_OVERLAY_FILES[light]}"
    target_file="${FSH_CACHE_FILES[light]}"
  fi

  local err_file=$(mktemp)

  if [[ -o zle ]]; then zle -I; fi

  # Set base theme
  fast-theme "$base_theme" 2>"$err_file"
  local retval=$?
  local err=$(<"$err_file")

  if (( retval )); then
    rm -f "$err_file"
    (( ${+ICE[silent]} == 0 )) && \
      echo "FSH: Failed setting base theme ($base_theme): $err"
    return 1
  fi

  # Apply overlay if it exists and is non-empty
  if [[ -f "$overlay_ini" && -s "$overlay_ini" ]]; then
    fast-theme "$overlay_ini" 2>"$err_file"
    retval=$?
    err=$(<"$err_file")

    if (( retval )); then
      rm -f "$err_file"
      (( ${+ICE[silent]} == 0 )) && \
        echo "FSH: Failed applying overlay ($overlay_ini): $err"
      return 1
    fi
  fi

  rm -f "$err_file"

  # Dump FAST_HIGHLIGHT_STYLES to cache file
  {
    echo "typeset -gA FAST_HIGHLIGHT_STYLES"
    local key val
    for key val in "${(kv@)FAST_HIGHLIGHT_STYLES}"; do
      printf "FAST_HIGHLIGHT_STYLES[%s]=%s\n" "${(q)key}" "${(q)val}"
    done
  } > "$target_file"
  zcompile -Uz -- "$target_file"

  (( ${+ICE[silent]} == 0 )) && \
    echo "FSH: Generated $mode theme ($base_theme + overlay)"
  return 0
}

function __generate_fsh_themes() {
  __generate_fsh_theme "dark"
  __generate_fsh_theme "light"

  # Update themes cache with currently generated theme names
  {
    echo "typeset -gA FSH_BASE_THEME"
    echo "FSH_BASE_THEME[dark]=\"$FSH_THEME_DARK\""
    echo "FSH_BASE_THEME[light]=\"$FSH_THEME_LIGHT\""
  } > "$FSH_THEMES_CACHE"
}

_safe_one_off_load __generate_fsh_themes
