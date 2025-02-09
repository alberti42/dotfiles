#!/hint/zsh

function __gnu_utils_atclone() {
  local additions quoted_list

  # Array of additional commands separated by commas
  additions=("gawk")
  
  # add the additional packages defined by 'additions'
  if [[ -n "$(command -v gsed)" ]]; then

    # Add quotation marks and join together by spaces
    quoted_list="'${(j:' ':)additions}'"
    
    # Add 'additions' to the snippet
    gsed -i"" "/^\s*gcmds=(/,/)/ {/^.*)/a\\
  \\
  # additions\\
  gcmds+=($quoted_list)
}" OMZP::gnu-utils
  else
    [[ ${ZINIT[MUTE_WARNINGS]} != (1|true|on|yes) && $quiet != -q ]] && \
      +zi-log "{u-warn}Warning{b-warn}: additional packages \{${additions[@]}} could not be installed"
  fi
}
_safe_one_off_load __gnu_utils_atclone
