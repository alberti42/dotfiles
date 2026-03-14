#!/bin/zsh -fd
#
# Minimal, deterministic environment for running Launch Agents under launchd (e.g., opencode).
#
# Keep this file focused on exported variables needed by opencode + its child
# processes (git/rg/pty shells/etc). Avoid interactive-only shell setup.

set -euo pipefail
set -o err_return
trap 'print -u2 -- "ERROR: ${0:t} failed at line $LINENO (exit $?)"; return 1' ERR

: "${HOME:?HOME is not set}"

(( $# >= 2 )) || {
  print -u2 -- "Usage: ${0:t} <pyenv-environment> <command> [args...]"
  exit 64
}

# pyenv enviornment to be activated
local pyenv_environment=$1
shift

# Command (and args) to be executed
local -a cmd_argv
cmd_argv=("$@")

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Keep PATH explicit. This is based on the current PATH in my zsh shell (Jan. 2026)
typeset -gaU path   # -a array, -U unique entries
path=(
  "$HOME/.local/share/zinit/plugins/ccache---ccache"
  "$HOME/.local/share/zinit/polaris/bin"
  "/opt/homebrew/lib/ruby/gems/3.4.0/bin"
  "/opt/homebrew/opt/ruby/bin"
  "/opt/homebrew/bin"
  "/Library/TeX/texbin"
  "$HOME/.local/bin"
  "$HOME/bin"
  "/usr/local/bin"
  "/usr/bin"
  "/bin"
  "/usr/sbin"
  "/sbin"
  "$HOME/.juliaup/bin"
  "$HOME/.cargo/bin"
)
 
source "$HOME/.config/dotfiles/zinit/src/pyenv/zi_pyenv_init.zsh"

# Activate pyenv
pyenv activate "$pyenv_environment"

exec -- "${cmd_argv[@]}"
