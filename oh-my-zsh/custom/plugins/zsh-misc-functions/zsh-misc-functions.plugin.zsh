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
    # -f — full-format listing.
    ps -ww -f -p "$pids"
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

# set the tty properties and flags explictly
restore_tty() {
  emulate -LR zsh

  # Disable terminal flow control (^S/^Q) and disable EOF (^D) on this TTY
  stty -ixon eof undef start undef stop undef
  
  # Blinking block
  printf '\e[1 q'
  
  # CSI u XTMODKEYS (modifyOtherKeys)
  #
  # - \e[> — CSI with > meaning "private/DEC" parameter prefix
  # - 4 — refers to key encoding (KeyModifierOptions)
  # - 1 — enable CSI-u mode for ambiguous sequences
  #
  # The full set:
  # - 0 — disable (reset to legacy)
  # - 1 — report modifiers for "other" keys (those without existing modifier handling)
  # - 2 — report modifiers for all keys
  printf '\e[>4;1m'
}

# Wrapper functions to launch a given utility with proper restoration of tty properties after exiting
wrap_restore_tty() {
  emulate -LR zsh
  setopt localoptions no_aliases

  local cmd orig safe

  for cmd in "$@"; do
    # Make a safe backup function name (in case cmd has odd chars)
    safe=${cmd//[^A-Za-z0-9_]/_}
    orig="__restore_tty_orig_${safe}"

    if (( $+functions[$cmd] )); then
      # It's a zsh function: copy it, so the wrapper can call the original
      functions -c -- "$cmd" "$orig"
    else
      # Not a function: treat as command/builtin (also avoids aliases due to no_aliases)
      if ! whence -w -- "$cmd" >/dev/null; then
        print -u2 -- "wrap_restore_tty: not found: $cmd"
        continue
      fi

      # Create a small trampoline that dispatches via `command`
      eval "function $orig() { command $cmd \"\$@\" }"
    fi

    # Define the wrapper itself
    eval "function $cmd() {
      local rc=1
      export INSIDE_${safe}=1
      {
        $orig \"\$@\"
        rc=\$?
      } always {
        unset INSIDE_${safe}
        restore_tty
        return \$rc    
      }
    }"
  done
}

pip_upgrade_outdated() {
  emulate -LR zsh
  local outdated=($(uv pip list --outdated --format=json | jq -r '.[].name'))
  (( ${#outdated[@]} )) && uv pip install -U "${outdated[@]}" || echo '✅ All packages are up to date!'
}
