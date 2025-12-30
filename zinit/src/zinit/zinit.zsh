#!/hint/zsh

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

# Disable interactive mode
ZINIT[NO_PAGER]=1
# Limit the maximum number of lines to log
ZINIT[NO_PAGER_MAX_LINES]=0

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
