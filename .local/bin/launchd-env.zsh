# Minimal, deterministic environment for running Launch Agents under launchd (e.g., opencode).
#
# Usage (example):
#   /bin/zsh -lc 'source "$HOME/.config/dotfiles/.local/bin/launchd-env.zsh" && pyenv activate py313 && exec opencode serve --port 4096'
#
# Keep this file focused on exported variables needed by opencode + its child
# processes (git/rg/pty shells/etc). Avoid interactive-only shell setup.

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

export PYENV_ROOT="$HOME/.pyenv"

# Keep PATH explicit. This is based on the current PATH
typeset -gx PATH
PATH=(
  "$PYENV_ROOT/shims"
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

# Make `pyenv activate ...` work in non-interactive shells.
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - zsh)" 2>/dev/null || true
  eval "$(pyenv virtualenv-init - zsh)" 2>/dev/null || true
fi

# Secure the server by setting a password.
export OPENCODE_SERVER_USERNAME="andrea"
export OPENCODE_SERVER_PASSWORD="..."
