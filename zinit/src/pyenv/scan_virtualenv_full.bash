#!/usr/bin/env bash

set -euo pipefail

PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
versions_dir="${PYENV_ROOT}/versions"

READLINK="$(command -v greadlink || command -v readlink || true)"
if [ -z "$READLINK" ]; then
  echo "scan: cannot find readlink" >&2
  exit 1
fi

resolve_link() {
  "$READLINK" "$1"
}

realpath() {
  local f="$1" name="" dir

  while [ -L "$f" ]; do
    f="$(resolve_link "$f")"
  done
  if [ ! -d "$f" ]; then
    name="/${f##*/}"
    dir="${f%/*}"
    if [ "$dir" = "$f" ]; then
      f="$PWD"
    else
      f="$dir"
    fi
  fi
  dir="$(cd "$f" && pwd)"
  echo "${dir}${name}"
}

usage() {
  echo "Usage: $(basename "$0") [--bare] [--skip-aliases]" >&2
}

unset bare
unset skip_aliases
for arg in "$@"; do
  case "$arg" in
  --bare ) bare=1 ;;
  --skip-aliases ) skip_aliases=1 ;;
  * ) usage; exit 1 ;;
  esac
done

if [ ! -d "$versions_dir" ]; then
  exit 0
fi

versions_dir="$(realpath "$versions_dir")"

current_versions=()
if [ -n "${bare:-}" ]; then
  hit_prefix=""
  miss_prefix=""
  unset print_origin
else
  hit_prefix="* "
  miss_prefix="  "
  if command -v pyenv-version-name >/dev/null 2>&1; then
    OLDIFS="$IFS"
    IFS=:
    current_versions=($(pyenv-version-name 2>/dev/null || true))
    IFS="$OLDIFS"
  elif [ -n "${PYENV_VERSION:-}" ]; then
    OLDIFS="$IFS"
    IFS=:
    current_versions=($PYENV_VERSION)
    IFS="$OLDIFS"
  fi
  print_origin="1"
fi

num_versions=0

exists() {
  local car="$1"
  local cdar
  shift
  for cdar in "$@"; do
    if [ "$car" = "$cdar" ]; then
      return 0
    fi
  done
  return 1
}

print_version() {
  if exists "$1" "${current_versions[@]}"; then
    echo "${hit_prefix}${1}${print_origin+$2}"
  else
    echo "${miss_prefix}${1}${print_origin+$2}"
  fi
  num_versions=$((num_versions + 1))
}

virtualenv_prefix_for_path() {
  local prefix_path="$1"
  local virtualenv_prefix=""
  local virtualenv_binpath=""
  local virtualenv_libpath=""
  local virtualenv_orig_prefix=""
  local conda_root=""

  if [ ! -x "${prefix_path}/bin/python" ]; then
    return 1
  fi

  if [ -f "${prefix_path}/bin/activate" ]; then
    if [ -f "${prefix_path}/bin/conda" ]; then
      virtualenv_prefix="${prefix_path}"
    elif [ -f "${prefix_path}/pyvenv.cfg" ]; then
      virtualenv_binpath="$(sed -n '/^ *home *= */s///p' "${prefix_path}/pyvenv.cfg" | head -1 || true)"
      virtualenv_prefix="${virtualenv_binpath%/bin}"
    else
      if [ -d "${prefix_path}/Lib" ]; then
        virtualenv_libpath="${prefix_path}/Lib"
      elif [ -d "${prefix_path}/lib-python" ]; then
        virtualenv_libpath="${prefix_path}/lib-python"
      else
        virtualenv_libpath="${prefix_path}/lib"
      fi
      virtualenv_orig_prefix="$(find "${virtualenv_libpath}/" -maxdepth 2 -type f -name "orig-prefix.txt" 2>/dev/null | head -1 || true)"
      if [ -n "${virtualenv_orig_prefix}" ] && [ -f "${virtualenv_orig_prefix}" ]; then
        virtualenv_prefix="$(cat "${virtualenv_orig_prefix}" 2>/dev/null || true)"
      fi
    fi
  elif [ -d "${prefix_path}/conda-meta" ]; then
    conda_root="$(realpath "${prefix_path}/../..")"
    virtualenv_prefix="${conda_root}"
  fi

  if [ -n "${virtualenv_prefix}" ] && [ -d "${virtualenv_prefix}" ]; then
    echo "${virtualenv_prefix}"
    return 0
  fi

  return 1
}

shopt -s dotglob
shopt -s nullglob
for base_path in "${versions_dir}"/*; do
  [ -d "$base_path" ] || continue

  if [ -n "${skip_aliases:-}" ] && [ -L "$base_path" ]; then
    target="$(realpath "$base_path")"
    [ "${target%/*/envs/*}" != "$versions_dir" ] || continue
  fi

  base_name="${base_path##*/}"
  if virtualenv_prefix="$(virtualenv_prefix_for_path "$base_path")"; then
    print_version "$base_name" " (created from ${virtualenv_prefix})"
  fi

  envs_dir="${base_path}/envs"
  if [ -d "$envs_dir" ]; then
    for env_path in "${envs_dir}"/*; do
      [ -d "$env_path" ] || continue
      env_name="${env_path##*/}"
      if virtualenv_prefix="$(virtualenv_prefix_for_path "$env_path")"; then
        print_version "${base_name}/envs/${env_name}" " (created from ${virtualenv_prefix})"
      fi
    done
  fi
done
shopt -u dotglob
shopt -u nullglob

# no warning on empty result (matches pyenv-virtualenvs)
