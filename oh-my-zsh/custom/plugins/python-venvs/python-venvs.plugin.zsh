# (c) Andrea Alberti, 2024

# Activate venv by passing the name of the venv or using local .venv/venv
function activate() {
  local env_path

  if [[ "$1" == "venv" && -d "./venv" ]]; then
    # Check for local ./venv
    env_path="$(pwd)/venv"
  elif [[ "$1" == ".venv" && -d "./.venv" ]]; then
    # Check for local ./.venv
    env_path="$(pwd)/.venv"
  else
    # Check for named virtual environment in ~/.virtualenvs
    env_path="$HOME/.virtualenvs/$1"
    if [[ ! -d "${env_path}" ]]; then
      echo "activate: unknown environment: ${env_path}"
      return 1
    fi
  fi

  # Activate the virtual environment
  source "${env_path}/bin/activate"
  echo "activate: activated environment at ${env_path}"
}

# Modify the fpath
fpath+="${0:A:h}"

# Auto-load the compinit function
autoload -U compinit
# Initialize the completion system
compinit
