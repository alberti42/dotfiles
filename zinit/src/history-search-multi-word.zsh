# https://github.com/zdharma-continuum/history-search-multi-word

function __history_smw_atinit() {
  zstyle :history-search-multi-word page-size 10
  zstyle :history-search-multi-word highlight-color fg=#ffffff,bg=#d200ff,bold
  # zstyle :history-search-multi-word active "underline"
  zstyle :plugin:history-search-multi-word reset-prompt-protect 1
}

function __history_smw_atload() {
  # Remove traditional ZSH binding for searching backward and forward in the history
  bindkey -r '^R'
  bindkey -r '^S'
  bindkey '^\' history-search-multi-word
}

# Load zdharma multi-word history search plugin
zinit ice wait light-mode depth=1 lucid \
  atinit:'_safe_one_off_load __history_smw_atinit' \
  atload:'_safe_one_off_load __history_smw_atload'

zinit light @zdharma-continuum/history-search-multi-word
