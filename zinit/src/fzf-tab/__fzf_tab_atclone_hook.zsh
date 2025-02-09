# Andrea Alberti, 2024

function __fzf_tab_atclone_hook() {
  [[ -n ${commands[gsed]} ]] && local PREFIX=${${(M)OSTYPE##darwin}:+g}
  # we overwrite "ls-colors.zsh" to prevent its loading; we use the compiled module
  echo "" >! ./lib/zsh-ls-colors/ls-colors.zsh &&
  : && # the script fzf-tab.zsh creates global fzf-tab.zsh without using "typeset -g"
  : && # we prevent the warning by temporarily disabling NO_WARN_CREATE_GLOBAL
  setopt NO_WARN_CREATE_GLOBAL &&
  source fzf-tab.zsh &&
  build-fzf-tab-module &&
  setopt WARN_CREATE_GLOBAL &&
  : && # we remove oh-my-zsh repository; otherwise all ~1000 completions are installed
  rm -rf "$FZF_TAB_HOME/modules/zsh" &&
  : && # we unset the global variable
  unset FZF_TAB_HOME
}
_safe_one_off_load __fzf_tab_atclone_hook
