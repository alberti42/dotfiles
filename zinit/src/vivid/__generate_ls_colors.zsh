#!/hint/zsh

function __generate_ls_colors_for_theme() {
  local theme="$1"
  local target_file="$2"
  
  # Capture both stdout and stderr
  local ls_colors
  local error_file=$(mktemp)  # Temporary file to capture stderr
  ls_colors=$(vivid generate "$theme" 2> "$error_file")
  local retval=$?
  local error_msg=$(<"$error_file")  # Read the error message from the temp file
  rm -f "$error_file"               # Clean up the temp file
  
  # Log result to the console
  if [[ -o zle ]]; then
    zle -I
  fi
  
  if [[ $retval -eq 0 ]]; then
    {
      echo -n "local LS_COLORS='"
      echo "$ls_colors" | tr -d "\n"
      echo "'"
      echo "export LS_COLORS"
    } > "$target_file"
    zcompile -Uz -- "$target_file"
    (( ${+ICE[silent]} == 0 )) && \
      echo "Vivid: Generated color scheme ($theme): $ZINIT[col-happy]$theme$ZINIT[col-rst]"
    return 0
  else
    (( ${+ICE[silent]} == 0 )) && \
      echo "$ZINIT[col-warn]Vivid: Failed generating color scheme ($theme): $error_msg$ZINIT[col-rst]"
    return 1
  fi
}

function __generate_ls_colors() {
  # We regenerate both themes for simplicity and to ensure the cache stays in sync
  __generate_ls_colors_for_theme "$THEME_DARK" "${LS_COLORS_FILES[dark]}"
  __generate_ls_colors_for_theme "$THEME_LIGHT" "${LS_COLORS_FILES[light]}"
  
  # Update cache with currently desired theme names
  {
    echo "typeset -gA LS_COLORS_THEME"
    echo "LS_COLORS_THEME[dark]=\"$THEME_DARK\""
    echo "LS_COLORS_THEME[light]=\"$THEME_LIGHT\""
  } > "$LS_COLORS_THEMES_CACHE"
}

_safe_one_off_load __generate_ls_colors
