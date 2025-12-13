function __fzf_preview_killall() {
  local name=$1
  local group=$2

  # Escape for pgrep regex (safe even if not strictly needed with -x)
  local escaped_name
  escaped_name=$(printf "%s" "$name" | sed 's/[][(){}.^$*+?|\\\\]/\\&/g')
  [[ -z "$escaped_name" ]] && exit 0

  # Detect whether completion is being done under sudo (best-effort)
  local is_sudo=0
  [[ ${_comp_priv_prefix[1]-} = sudo ]] && is_sudo=1

  if [[ $OSTYPE = darwin* ]]; then
    local pids
    pids="$(pgrep -x "$escaped_name" 2>/dev/null | head -200)"
    if [[ -z "$pids" ]]; then
      echo "No exact matches for: $escaped_name"
      echo
      echo "Tip: killall on macOS matches process names (comm)."
      exit 0
    fi

    echo -e "\033[1;36mTARGET\033[0m: $name"
    echo -e "\033[1;36mMATCHES\033[0m: $(echo "$pids" | wc -l | tr -d " ")"
    [[ $is_sudo = 1 ]] && echo -e "\033[1;33mNOTE\033[0m: running under sudo may target other users’ processes"
    echo

    # Convert newline PID list -> comma list for ps/lsof -p
    local pidlist
    pidlist="${(j:,:)=${(f)pids}}"

    # Batch lsof once: build PID -> exe path map.
    # lsof -F output is record-based, e.g.:
    #   p1234
    #   n/path/to/exe
    # We ask only for txt (the mapped executable "text" file).
    local -A EXE_BY_PID
    local curpid=""
    local line
    local IFS=$' \t\n'
    while read -r line; do
      case $line in
        p*) curpid=${line#p} ;;
        n*) [[ -n "$curpid" && -z "${EXE_BY_PID[$curpid]-}" ]] && EXE_BY_PID[$curpid]=${line#n} ;;
      esac
    done < <(lsof -n -a -d txt -Fp -Fn -p "$pidlist" 2>/dev/null)

    # Print table (PID/USER/ETIME/COMM/EXE)
    local pid user et comm exe
    local n=0
    while read -r pid user et; do
      (( ++n > 80 )) && break
      exe="${EXE_BY_PID[$pid]-}"
      [[ -z "$exe" ]] && exe="(exe unknown)"
      printf "\033[1;36m%-6s\033[0m \033[1;33m%-10s\033[0m \033[1;32m%-10s\033[0m \033[1;35m%-16s\033[0m %s\n" \
        "$pid" "$user" "$et" "$exe"
    done < <(ps -p "$pidlist" -o pid=,user=,etime=, -ww 2>/dev/null)

  else
    # Linux
    local pids
    pids="$(pgrep -x -- "$escaped_name" 2>/dev/null | head -200)"
    if [[ -z "$pids" ]]; then
      echo "No exact matches for: $escaped_name"
      echo
      echo "Tip: try -I/--ignore-case or -r/--regexp (if your killall supports it)."
      exit 0
    fi

    echo -e "\033[1;36mTARGET\033[0m: $escaped_name"
    echo -e "\033[1;36mMATCHES\033[0m: $(echo "$pids" | wc -l | tr -d " ")"
    [[ $is_sudo = 1 ]] && echo -e "\033[1;33mNOTE\033[0m: running under sudo may target other users’ processes"
    echo

    # Convert newline PID list -> comma list for ps -p
    local pidlist
    pidlist="$(echo "$pids" | paste -sd, -)"

    # read splits into pid/user/etime/comm, and puts the remainder into args
    local pid user et comm
    local n=0
    local IFS=$' \t\n'
    while read -r pid user et comm; do
      (( ++n > 80 )) && break
      printf "\033[1;36m%-6s\033[0m \033[1;33m%-10s\033[0m \033[1;32m%-10s\033[0m \033[1;35m%-16s\033[0m\n" \
        "$pid" "$user" "$et" "$comm"
    done < <(ps -p "$pidlist" -o pid=,user=,etime=,comm= -ww 2>/dev/null)
  fi
}

# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :