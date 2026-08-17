# Andrea Alberti, 2026

function __lsp-ltex-plus_atclone_hook() {
  emulate -L zsh
  setopt extendedglob

  # Sanity-check at clone time that a bundled JDK is present
  local -a jdk_matches=( "${PWD}"/jdk-*(/N) )
  if (( ${#jdk_matches} == 0 )); then
    print -u2 "ltex-plus atclone: no jdk-* directory found in ${PWD}"
    return 1
  fi

  local plugin_dir="${PWD}"
  local cmd
  for cmd in ltex-ls-plus ltex-cli-plus; do
    command rm -f "$ZPFX/bin/$cmd"
    cat > "$ZPFX/bin/$cmd" <<EOF
#!/usr/bin/env zsh -fd
plugin_dir="$plugin_dir"
jdk_dir=("\$plugin_dir"/jdk-*(/Nom[1]))
if (( \${#jdk_dir} == 0 )); then
  print -u2 "$cmd wrapper: no jdk-* directory found in \$plugin_dir"
  exit 1
fi
export JAVA_HOME="\${jdk_dir[1]}"
exec "\$plugin_dir/bin/$cmd" "\$@"
EOF
    chmod +x "$ZPFX/bin/$cmd"
  done
}

_safe_one_off_load __lsp-ltex-plus_atclone_hook

## vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
