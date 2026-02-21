# Andrea Alberti, 2026

function __lsp-ltex-plus_atclone_hook() {
  emulate -L zsh
  setopt extendedglob
  # Resolve the bundled JDK path
  local -a jdk_matches=( "${PWD}"/jdk-*(N) )
  local jdk_dir="${jdk_matches[1]:a}"
  
  # Create wrapper shims in $ZPFX/bin with local JAVA_HOME
  local cmd
  for cmd in ltex-ls-plus ltex-cli-plus; do
    cat > "$ZPFX/bin/$cmd" <<EOF
#!/usr/bin/env zsh -fd
export JAVA_HOME="$jdk_dir"
exec "${PWD}/bin/$cmd" "\$@"
EOF
    chmod +x "$ZPFX/bin/$cmd"
  done
}

_safe_one_off_load __lsp-ltex-plus_atclone_hook

## vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :