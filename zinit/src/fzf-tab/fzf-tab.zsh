# https://github.com/Aloxaf/fzf-tab

function __fzf_tab_init_hook() {
  # disable sort when completing `git checkout`
  zstyle ":completion:*:git-checkout:*" sort false
  
  # force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
  zstyle ':completion:*' menu no

  # set descriptions format to enable group support
  # Note: don't use escape sequences (like '%F{red}%d%f') here; fzf-tab will ignore them
  zstyle ':completion:*:descriptions' format '[%d]'
  
  # disable sort when completing `git checkout`
  zstyle ':completion:*:git-checkout:*' sort false

  # NOTE: Check https://github.com/Aloxaf/fzf-tab/wiki/Configuration#zstyle for customization of zstyle
  
  # switch group using `<` and `>`
  zstyle ':fzf-tab:*' switch-group '<' '>'

  # give a preview of commandline arguments when completing `kill`
  zstyle ':fzf-tab:complete:(kill|ps):*' fzf-preview '
    # Only show this preview for PID candidates
    [[ $group != "[process ID]" ]] && return 0

    pid="$word"
    [[ -z "$pid" ]] && return 0

    if [[ $OSTYPE = darwin* ]]; then
      # macOS ps: no "lstart" and different flags
      ps -p "$pid" -o pid=,ppid=,user=,pcpu=,pmem=,start=,tty=,comm=,args= -ww 2>/dev/null |
      awk '"'"'{
        PID=$1; PPID=$2; USER=$3; CPU=$4; MEM=$5; START=$6; TTY=$7; COMM=$8;
        $1=$2=$3=$4=$5=$6=$7=$8="";
        sub(/^ +/,"");
        printf "\033[1;36mPID\033[0m: %s  \033[1;36mPPID\033[0m: %s\n", PID, PPID;
        printf "\033[1;33mUSER\033[0m: %s  \033[1;32mCPU\033[0m: %s%%  \033[1;35mMEM\033[0m: %s%%\n", USER, CPU, MEM;
        printf "\033[1;34mSTART\033[0m: %s  \033[1;34mTTY\033[0m: %s\n", START, TTY;
        printf "\033[1;32mCOMM\033[0m: %s\n", COMM;
        printf "\033[1;35mARGS\033[0m: %s\n", $0;
      }'"'"'
    else
      # Linux ps: lstart is nice and args can be made very wide
      ps -p "$pid" -o pid=,ppid=,user=,pcpu=,pmem=,lstart=,tty=,comm=,args= -ww 2>/dev/null |
      awk '"'"'{
        PID=$1; PPID=$2; USER=$3; CPU=$4; MEM=$5;
        START=$6" "$7" "$8" "$9" "$10;
        TTY=$11; COMM=$12;
        $1=$2=$3=$4=$5=$6=$7=$8=$9=$10=$11=$12="";
        sub(/^ +/,"");
        printf "\033[1;36mPID\033[0m: %s  \033[1;36mPPID\033[0m: %s\n", PID, PPID;
        printf "\033[1;33mUSER\033[0m: %s  \033[1;32mCPU\033[0m: %s%%  \033[1;35mMEM\033[0m: %s%%\n", USER, CPU, MEM;
        printf "\033[1;34mSTART\033[0m: %s\n", START;
        printf "\033[1;34mTTY\033[0m: %s\n", TTY;
        printf "\033[1;32mCOMM\033[0m: %s\n", COMM;
        printf "\033[1;35mARGS\033[0m: %s\n", $0;
      }'"'"'
    fi
  '
  
  zstyle ':fzf-tab:complete:killall:*' fzf-preview '
    # Name of process
    name="$word"
    # Escape for pgrep regex
    escaped_name=$(printf "%s" "$name" | sed "s/[\(\)\{\}\.\^\$\*]/\\\\&/g")
    [[ -z "$escaped_name" ]] && exit 0

    # Detect whether completion is being done under sudo (best-effort)
    is_sudo=0
    [[ ${_comp_priv_prefix[1]-} = sudo ]] && is_sudo=1

    if [[ $OSTYPE = darwin* ]]; then
      # macOS: pgrep + ps (etime is supported; args needs -ww)
      pids="$(pgrep -x "$escaped_name" 2>/dev/null | head -200)"
      if [[ -z "$pids" ]]; then
        echo "No exact matches for: $escaped_name"
        echo
        echo "Tip: killall on macOS matches process *escaped_names* (comm)."
        exit 0
      fi

      echo -e "\033[1;36mTARGET\033[0m: $name"
      echo -e "\033[1;36mMATCHES\033[0m: $(echo "$pids" | wc -l | tr -d " ")"
      [[ $is_sudo = 1 ]] && echo -e "\033[1;33mNOTE\033[0m: running under sudo may target other users’ processes"
      echo

      # Show a compact table
      ps -p "${(j:,:)=${(f)pids}}" -o pid=,user=,etime=,comm=,args= -ww 2>/dev/null |
        head -60 |
        awk '"'"'{
          PID=$1; USER=$2; ET=$3; COMM=$4;
          $1=$2=$3=$4=""; sub(/^ +/,"");
          printf "\033[1;36m%-6s\033[0m \033[1;33m%-10s\033[0m \033[1;32m%-10s\033[0m \033[1;35m%-16s\033[0m %s\n",
                 PID, USER, ET, COMM, $0
        }'"'"'
    else
      # Linux: pgrep + ps; we’ll show PID/USER/ELAPSED/COMM/ARGS
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
      pidlist="$(echo "$pids" | paste -sd, -)"
      ps -p "$pidlist" -o pid=,user=,etime=,comm=,args= -ww 2>/dev/null |
        head -80 |
        awk '"'"'{
          PID=$1; USER=$2; ET=$3; COMM=$4;
          $1=$2=$3=$4=""; sub(/^ +/,"");
          printf "\033[1;36m%-6s\033[0m \033[1;33m%-10s\033[0m \033[1;32m%-10s\033[0m \033[1;35m%-16s\033[0m %s\n",
                 PID, USER, ET, COMM, $0
        }'"'"'
    fi
  '

  # no prview for options
  zstyle ':fzf-tab:complete:*:options' fzf-preview ''

  # no preview for subcommands
  # zstyle ':fzf-tab:complete:*:argument-1' fzf-preview ''

  # preview for files
  local script_path="${(%):-%x}"
  zstyle ":fzf-tab:complete:*:*" fzf-preview "__zcompile_if_needed_and_source '${script_path:h}/__fzf_file_preview.zsh' && __fzf_file_preview \$realpath"

  # Force fzf-tab to use FZF_DEFAULT_OPTS; fzf-tab does not follow FZF_DEFAULT_OPTS by default
  # NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
  zstyle ':fzf-tab:*' use-fzf-default-opts yes
  
  zstyle ":fzf-tab:*" fzf-flags \
    "--ansi" \
    "--bind=tab:accept" \
    "--height=70%" \
    "--preview-window=right:60%" \
    "--padding=0,1,0,0" \
    "--min-height=20"
}

# Enable preview only for files and directories
# zstyle ':fzf-tab:complete:*:(files|directories)' fzf-preview 'ls --color=auto -l $realpath'

# Add fzf support to zsh; check https://thevaluable.dev/practical-guide-fzf-example/
# It requires zicompinit; zicompinit; so it must be called after fast-syntax-highlighting
zinit ice depth=1 wait light-mode lucid \
  atclone"source '${${(%):-%x}:h}/__fzf_tab_atclone_hook.zsh'" \
  atinit'_safe_one_off_load __fzf_tab_init_hook' \
  id-as'Aloxaf/fzf-tab'
zinit light Aloxaf/fzf-tab
