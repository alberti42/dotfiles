# Turbo loading of local configuration files under ~/.rc_local

if [[ -d $HOME/.rc_local ]]; then
  local config_files=(${HOME}/.rc_local/*.zsh(N))  # Collect .zsh files, empty array if none
  if (( ${#config_files[@]} > 0 )); then
    local -a zinit_snippets
    for file in "${config_files[@]}"; do
      local filename=${file:t:r}  # Extract filename without directory or extension
      zinit_snippets+=("id-as:local/${filename}" "${file}")  # id-as as one string
    done
    zinit is-snippet wait lucid for "${(@)zinit_snippets}"
  fi
fi
