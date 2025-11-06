function __zcompile_if_needed_and_source() {
  # Utility function to compile zsh files and execute them
  local script="$1"
  local compiled_script="${script}.zwc"

  if [[ ! -f "$compiled_script" || "$script" -nt "$compiled_script" ]]; then    
    zcompile -Uz -- "$script" "$compiled_script"  
  fi
  builtin source "$@"
}
