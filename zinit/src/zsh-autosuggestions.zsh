# https://github.com/zsh-users/zsh-autosuggestions

function __my_autosuggest_atinit_hook() {
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#333333,bold"
  ZSH_AUTOSUGGEST_MANUAL_REBIND=1 # make prompt faster
}

# Load autosuggestions
zinit ice wait depth=1 light-mode lucid \
  atinit'_safe_one_off_load __my_autosuggest_atinit_hook' \
  atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions
