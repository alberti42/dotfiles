#!/hint/zsh

###########################################
#  Useful small utility functions
#  Copyright (c) 2025, Andrea Alberti
###########################################

# Retrieve ip addresses
ip-internal() {
  emulate -LR zsh
  echo "Wireless  :: IP => $( ipconfig getifaddr en0 )"
}
ip-external() {
  emulate -LR zsh
  echo "External :: IP => $( curl --silent https://ifconfig.me )"
}
ip-info() {
  emulate -LR zsh
  ip-internal && ip-external
}

# Find processes matching the pattern
function ppgrep() {
  emulate -LR zsh
  # Collect PIDs as a single comma-separated string (works on BSD + GNU)
  local pids
  pids=$(pgrep -f -d ',' "$@") || return
  [[ -n $pids ]] || return

  if [[ $OSTYPE = darwin* ]]; then
    # macOS / BSD-style flags
    # -x — show processes without a controlling terminal.
    # -w — wide output.
    # -p — specify PID list (works with both BSD and GNU).
    ps -x -w -p "$pids"
  else
    # UNIX/GNU-style flags; -ww = don't truncate command
    # -w — wide output. Use this option twice for unlimited width.
    # -p — specify PID list (works with both BSD and GNU).
    ps -ww -p "$pids"
  fi
}

# Clear screen and scroll back
function clc() {
  emulate -LR zsh
  # clear screen
  command clear
  # clear terminal history
  printf '\033[3J'
}

# Show current directory of given process PID
function pwdx() {
  emulate -LR zsh
  lsof -a -d cwd -p $1 -n -Fn | awk '/^n/ {print substr($0,2)}';
}

reload!() {
  emulate -LR zsh

  # Reset the path array (ensuring no duplicates)
  unset path
  typeset -U path
  path=(
      /usr/local/bin
      /usr/bin
      /bin
      /usr/sbin
      /sbin
  )
  # Export PATH from the cleaned path array
  export PATH="${(j.:.)path}"
  # Preserve essential environment variables while resetting everything else
  exec env PATH=$PATH $SHELL --login
}

# set the cursor style explictly
restore_cursor() {
  emulate -LR zsh
  echo -ne '\e[5 q'
}

# launch a given utility with proper restoration of cursor after exiting
wrap_restore_cursor() {
  emulate -LR zsh
  for cmd in "$@"; do
    eval "
${cmd}() {
  command ${cmd} \"\$@\"
  local rc=\$?
  restore_cursor
  return \$rc
}
"
  done
}

is_dark_appearance() {
  emulate -LR zsh
  local __is_dark="0"  # default answer
  if [[ $OSTYPE =~ 'darwin*' ]]; then
    if [[ $(defaults read $HOME/Library/Preferences/.GlobalPreferences.plist AppleInterfaceStyle 2>/dev/null) = Dark ]]; then
      __is_dark=1
    else
      __is_dark=0
    fi
  else
    # Linux
  fi
  printf "%s" $__is_dark
}

pip_upgrade_outdated() {
  emulate -LR zsh
  local outdated=($(uv pip list --outdated --format=json | jq -r '.[].name'))
  (( ${#outdated[@]} )) && uv pip install -U "${outdated[@]}" || echo '✅ All packages are up to date!'
}
