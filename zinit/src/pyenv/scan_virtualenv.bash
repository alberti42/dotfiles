#!/usr/bin/env bash

set -euo pipefail

PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
versions_dir="${PYENV_ROOT}/versions"

if [ ! -d "$versions_dir" ]; then
  exit 0
fi

is_virtualenv_dir() {
  local path="$1"

  # Match pyenv-virtualenv-prefix behavior: require python and activation marker.
  if [ ! -x "${path}/bin/python" ]; then
    return 1
  fi
  if [ -f "${path}/bin/activate" ] || [ -d "${path}/conda-meta" ]; then
    return 0
  fi
  return 1
}

shopt -s nullglob
shopt -s dotglob
for base_path in "${versions_dir}"/*; do
  [ -d "$base_path" ] || continue
  base_name="${base_path##*/}"

  if is_virtualenv_dir "$base_path"; then
    printf '%s\n' "$base_name"
  fi

  envs_dir="${base_path}/envs"
  if [ -d "$envs_dir" ]; then
    for env_path in "${envs_dir}"/*; do
      [ -d "$env_path" ] || continue
      env_name="${env_path##*/}"
      if is_virtualenv_dir "$env_path"; then
        printf '%s\n' "${base_name}/envs/${env_name}"
      fi
    done
  fi
done
shopt -u dotglob
shopt -u nullglob
