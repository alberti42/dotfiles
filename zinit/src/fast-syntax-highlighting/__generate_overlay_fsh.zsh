#!/hint/zsh

function __generate_overlay_fsh() {
  # $overlay_ini was modified more recently than $overlay_zsh, or $overlay_zsh does not exist
  # Update $overlay_zsh to reflect changes in overlay_ini
  local retval msg err err_file
  err_file=$(mktemp) # Create a temporary file for capturing stderr

  # Capture stdout and stderr separately
  msg=$(fast-theme "$overlay_ini" 2>"$err_file")
  retval=$?

  # Read the captured stderr
  err=$(<"$err_file")
  rm -f "$err_file" # Clean up the temporary file
  
  if (( retval )); then
      # Log failure
      if [[ ${ZINIT[MUTE_WARNINGS]} != (1|true|on|yes) && $quiet != -q ]]; then
          +zi-log "${ZINIT[col-error]}Error: Fast Syntax Highlighting: overlay.ini not processed correctly:${ZINIT[col-rst]} ${err}"
      fi
      return 1
  else
      # Log success
      if [[ ${ZINIT[MUTE_WARNINGS]} != (1|true|on|yes) && $quiet != -q ]]; then
          +zi-log "Fast Syntax Highlighting: ${ZINIT[col-data]}overlay.ini${ZINIT[col-rst]} processed correcty."
      fi
      if [[ -f "$overlay_zsh" ]]; then
        source "$overlay_zsh"
      else
        # When overlay.ini contains no configuration, no file is created
        # To avoid processing overlay.ini every new shell, we create an empty overlay.zsh
        touch "$overlay_zsh"
      fi
      return 0
  fi
  return 0
}
_safe_one_off_load __generate_overlay_fsh
