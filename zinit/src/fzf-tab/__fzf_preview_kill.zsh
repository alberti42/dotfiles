function __fzf_preview_kill() {
  local pid=$1
  local group=$2

  # Only show this preview for PID candidates
  [[ $group != "[process ID]" ]] && return 0
  [[ -z "$pid" ]] && return 0

  if [[ $OSTYPE = darwin* ]]; then
    # macOS: start= is short; comm is truncated; use lsof txt for full executable path
    local PID thePPID USER CPU MEM START TTY COMM args exe

    # Read exactly one line; last var captures the rest (args) including spaces
    local IFS=$' \t\n'
    read -r PID thePPID USER CPU MEM START TTY COMM args < <(
      ps -p "$pid" -o pid=,ppid=,user=,pcpu=,pmem=,start=,tty=,comm=,args= -ww 2>/dev/null | head -n1
    ) || return 0

    exe="$(lsof -n -p "$PID" -a -d txt -Fn 2>/dev/null | sed -n 's/^n//p' | head -n1)"
    [[ -z "$exe" ]] && exe="(exe unknown)"

    # Strip executable from args only if it is an exact prefix
    if [[ -n "$exe" && "$args" == "$exe" ]]; then
      args=""
    elif [[ -n "$exe" && "$args" == "$exe "* ]]; then
      args="${args#"$exe "}"
    fi

    printf "\033[1;36mPID\033[0m: %s  \033[1;36mPPID\033[0m: %s\n" "$PID" "$thePPID"
    printf "\033[1;33mUSER\033[0m: %s  \033[1;32mCPU\033[0m: %s%%  \033[1;35mMEM\033[0m: %s%%\n" "$USER" "$CPU" "$MEM"
    printf "\033[1;34mSTART\033[0m: %s  \033[1;34mTTY\033[0m: %s\n" "$START" "$TTY"
    printf "\033[1;32mCOMM\033[0m: %s\n" "$exe"
    printf "\033[1;35mARGS\033[0m: %s\n" "$args"

  else
    # Linux: lstart is 5 fields: "Mon Jan  1 00:00:00 2025"
    local PID thePPID USER CPU MEM s1 s2 s3 s4 s5 TTY COMM args START exe

    # Split fields; last var (args) captures the rest including spaces
    local IFS=$' \t\n'
    read -r PID thePPID USER CPU MEM s1 s2 s3 s4 s5 TTY COMM args < <(
      ps -p "$pid" -o pid=,ppid=,user=,pcpu=,pmem=,lstart=,tty=,comm=,args= -ww 2>/dev/null | head -n1
    ) || return 0

    START="$s1 $s2 $s3 $s4 $s5"

    # Best-effort: get real executable path (if lsof is available)
    exe=""
    if command -v lsof >/dev/null 2>&1; then
      exe="$(lsof -n -p "$PID" -a -d txt -Fn 2>/dev/null | sed -n 's/^n//p' | head -n1)"
    fi

    # Strip executable / command from args only if it is an exact prefix
    if [[ -n "$exe" ]]; then
      if [[ "$args" == "$exe" ]]; then
        args=""
      elif [[ "$args" == "$exe "* ]]; then
        args="${args#"$exe "}"
      fi
    elif [[ -n "$COMM" ]]; then
      if [[ "$args" == "$COMM" ]]; then
        args=""
      elif [[ "$args" == "$COMM "* ]]; then
        args="${args#"$COMM "}"
      fi
    fi

    printf "\033[1;36mPID\033[0m: %s  \033[1;36mPPID\033[0m: %s\n" "$PID" "$thePPID"
    printf "\033[1;33mUSER\033[0m: %s  \033[1;32mCPU\033[0m: %s%%  \033[1;35mMEM\033[0m: %s%%\n" "$USER" "$CPU" "$MEM"
    printf "\033[1;34mSTART\033[0m: %s\n" "$START"
    printf "\033[1;34mTTY\033[0m: %s\n" "$TTY"
    printf "\033[1;32mCOMM\033[0m: %s\n" "$COMM"
    printf "\033[1;35mARGS\033[0m: %s\n" "$args"
  fi
}


# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :