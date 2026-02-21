# Export root dir for pyenv
export PYENV_ROOT="$HOME/.pyenv"

# Update path
local -U unique_path
path=("${PYENV_ROOT}/shims" $path)

# Export pyenv shell variable
export PYENV_SHELL=zsh

# Installs shims for all Python binaries known to pyenv (i.e., ~/.pyenv/versions/*/bin/*).
# Run this command after you install a new version of Python, or install a package that provides binaries.
# command pyenv rehash

# Define pyenv wrap function
pyenv() {
  local command=${1:-}
  [ "$#" -gt 0 ] && shift
  case "$command" in
    activate|deactivate|rehash|shell)
      eval "$(command pyenv "sh-$command" "$@")"
      ;;
    *)
      command pyenv "$command" "$@"
      ;;
  esac
}
