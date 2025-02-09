#!/hint/zsh

##############################
# Zsh management functions   #
##############################

function __zcompile_if_needed_and_source() {
  # Utility function to compile zsh files and execute them
  local script="$1"
  local compiled_script="${script}.zwc"

  if [[ ! -f "$compiled_script" || "$script" -nt "$compiled_script" ]]; then    
    zcompile -Uz -- "$script" "$compiled_script"  
  fi
  builtin source "$@"
}

function _safe_one_off_load() {
  emulate -LR zsh

  local func=$1
  shift  # Remove the function name from the arguments
  local retval

  # Save the original state of ERR_EXIT
  local original_err_exit=${options[ERR_EXIT]}

  set -e  # Enable ERR_EXIT for this function
  "$func" "$@"  # Call the function with remaining arguments
  retval=$?

  # Restore the original state of ERR_EXIT
  if [[ $original_err_exit == off ]]; then
    set +e
  fi

  unfunction "$func"

  if [[ $retval -ne 0 ]]; then
    +zi-log "{error}Function '$func' exited with error code: $retval{rst}"
  fi
  return $retval
}

###########################
# zinit installation      #
###########################

# Zinit configurations
declare -A ZINIT

# Define the directory where Zinit will be installed
ZINIT[HOME_DIR]=$HOME/.local/share/zinit
# Zinit will not set aliases such as zi or zini
ZINIT[NO_ALIASES]=1
# Path to .zcompdump file
[[ ! -d ${XDG_CACHE_HOME:-$HOME/.cache}/zsh ]] && command mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
ZINIT[ZCOMPDUMP_PATH]=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump

# Check if Zinit is not already installed
if [[ ! -f $ZINIT[HOME_DIR]/zinit.git/zinit.zsh ]]; then
  source "${${(%):-%x}:h}/__my_install_zinit.zsh"
fi

# Source the Zinit main script to load its functionality (about 30 ms)
__zcompile_if_needed_and_source "$ZINIT[HOME_DIR]/zinit.git/zinit.zsh"

# Autoload the Zinit completion function (_zinit) to allow zsh's completion system to use it
autoload -Uz _zinit

# Safeguard for completion mapping:
# Check if `_comps` (the associative array for completions) is available.
# If it exists, map the `zinit` command to the `_zinit` completion function.
# This avoids errors if `_comps` isn't initialized yet (e.g., `compinit` hasn't run).
(( ${+_comps} )) && _comps[zinit]=_zinit

# Notes:
# - `compinit` is not invoked here to adhere to Zinit's philosophy of running it only once,
#   typically at the end of `.zshrc`, to ensure optimal performance and avoid conflicts.
# - The completion mapping ensures that if `_comps` is already initialized (e.g., during a re-source),
#   Zinit's completion function is correctly registered without redundant `compinit` calls.
# - This approach provides robustness and minimizes interference with the user's customizations.

