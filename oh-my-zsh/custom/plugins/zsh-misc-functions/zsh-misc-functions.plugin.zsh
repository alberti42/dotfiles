#!/hint/zsh

###########################################
#  Useful small utility functions
#  Copyright (c) 2025, Andrea Alberti
###########################################

# Retrieve ip addresses
function ip-internal() {
  emulate -LR zsh
  echo "Wireless  :: IP => $( ipconfig getifaddr en0 )"
}
function ip-external() {
  emulate -LR zsh
  echo "External :: IP => $( curl --silent https://ifconfig.me )"
}
function ip-info() {
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

# Show who issued an X.509 certificate, who it is for, and when it expires.
# Takes the PEM as one string, so quote it: certinfo "$(pbpaste)". Text around
# the PEM block is ignored, so a whole browser certificate-error page works.
# Each certificate in the string is printed in turn, so a chain arrives leaf
# first.
#
# Examples:
#
# certinfo "$(pbpaste)"        # a certificate copied from a browser error page
# certinfo "$(cat some.pem)"   # from a file
# pbpaste | certinfo
function certinfo() {
  emulate -LR zsh

  local input
  if (( $# > 1 )); then
    print -u2 -- 'certinfo: quote the PEM as one argument'
    return 1
  elif (( $# == 1 )); then
    input=$1
  elif [[ ! -t 0 ]]; then
    # Input file descriptor
    input=$(cat)
  else
      print -u2 -- 'certinfo: pass a PEM as one quoted argument, or pipe one in'
      return 1
  fi
  
  local total
  total=$(print -r -- "$input" | grep -c -- '-----BEGIN CERTIFICATE-----')
  if (( total == 0 )); then
    print -u2 -- 'certinfo: no PEM certificate in the argument; quote it, as in certinfo "$(pbpaste)"'
    return 1
  fi

  # LibreSSL, which is the /usr/bin/openssl on macOS, has no -ext option.
  # Prefer a real OpenSSL when one is installed, and drop the option otherwise.
  local ossl=openssl
  local -a extopt
  if openssl version | grep -q LibreSSL; then
    local brew
    for brew in /opt/homebrew/opt/openssl/bin/openssl /usr/local/opt/openssl/bin/openssl; do
      [[ -x $brew ]] && { ossl=$brew; break }
    done
  fi
  $ossl version | grep -q LibreSSL || extopt=(-ext subjectAltName)

  local n
  for (( n = 1; n <= total; n++ )); do
    (( total > 1 )) && print -r -- "===== certificate $n of $total ====="
    print -r -- "$input" \
      | awk -v want=$n '
          /-----BEGIN CERTIFICATE-----/ { seen++ }
          seen == want                  { print }
          seen == want && /-----END CERTIFICATE-----/ { exit }' \
      | $ossl x509 -noout -issuer -subject -dates -fingerprint -sha256 $extopt
  done
}

# Decode base64 and report what came out: the detected file type, the size,
# and the first readable strings. Takes the blob as one string, so quote it:
# b64peek "$(pbpaste)". PEM armour and whitespace are stripped, so a copied
# block works as is.
#
# Examples:
#
# b64peek  "$(pbpaste)"
# pbpaste | b64peek
function b64peek() {
  emulate -LR zsh

  local input
  if (( $# > 1 )); then
    print -u2 -- 'certinfo: quote the PEM as one argument'
    return 1
  elif (( $# == 1 )); then
    input=$1
  elif [[ ! -t 0 ]]; then
    # Input file descriptor
    input=$(cat)
  else
      print -u2 -- 'certinfo: pass a PEM as one quoted argument, or pipe one in'
      return 1
  fi

  # Strip the PEM armour and the whitespace, then map the two base64url
  # characters onto their standard spellings so that a JWT segment decodes
  # too. Neither _ nor - is valid in standard base64, so nothing else moves.
  local blob
  blob=$(print -r -- "$input" | grep -v -- '^-----' | tr -d '[:space:]' | tr '_-' '/+')
  if [[ -z $blob ]]; then
    print -u2 -- 'b64peek: no base64 data in the argument; quote it, as in b64peek "$(pbpaste)"'
    return 1
  fi

  local tmp
  # Spell the template out rather than using -t: GNU mktemp, which the
  # coreutils gnubin directory puts ahead of the BSD one, rejects a -t
  # argument that carries no X placeholders.
  tmp=$(mktemp "${${TMPDIR:-/tmp}%/}/b64peek.XXXXXXXX") || return
  {
    if ! print -rn -- "$blob" | base64 -d > $tmp 2>/dev/null; then
      print -u2 -- "b64peek: the argument is not valid base64"
      return 1
    fi

    print -r -- "type  : $(file -b -- $tmp)"
    print -r -- "bytes : $(wc -c < $tmp | tr -d ' ')"
    print -r -- "sha256: $(shasum -a 256 < $tmp | cut -d' ' -f1)"
    print -r -- "strings:"
    strings -n 4 -- $tmp | head -n 20
  } always {
    rm -f -- $tmp
  }
}
