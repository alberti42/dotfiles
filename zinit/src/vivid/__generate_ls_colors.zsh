#!/hint/zsh

function __generate_ls_colors() {
  # Capture both stdout and stderr
  local ls_colors
  local error_file=$(mktemp)  # Temporary file to capture stderr
  ls_colors=$(vivid generate "$ls_color_theme" 2> "$error_file")
  local retval=$?
  local error_msg=$(<"$error_file")  # Read the error message from the temp file
  rm -f "$error_file"               # Clean up the temp file
  
  echo "${plugin_dir}"

  # Log result to the console
  if [[ -o zle ]]; then
    zle -I
  fi
  if [[ $retval -eq 0 ]]; then
    {
      echo -n "LS_COLORS='"
      echo "$ls_colors" | tr -d "\n"
      echo "'"
      echo "export LS_COLORS"
    } > "$src_ls_colors_file"
    zcompile -Uz -- "$src_ls_colors_file"
    echo "$ls_colors" > "$ls_colors_file"
    (( ${+ICE[silent]} == 0 )) && \
      echo "Vivid: Generated color scheme: $ZINIT[col-happy]$ls_color_theme$ZINIT[col-rst]"
      return 0
  else
    (( ${+ICE[silent]} == 0 )) && \
      echo "$ZINIT[col-warn]Vivid: Failed generating color scheme: $error_msg$ZINIT[col-rst]"
      return 1
  fi
}
_safe_one_off_load __generate_ls_colors
