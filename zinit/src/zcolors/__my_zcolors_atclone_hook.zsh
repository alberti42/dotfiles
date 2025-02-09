#!/hint/zsh
function __my_zcolors_atclone_hook() {
  # If dircolors is not found, then consider the darwin variant with prefix
  [[ -n ${commands[gsed]} ]] && local PREFIX=${${(M)OSTYPE##darwin}:+g}
  
  autoload -Uz colors; colors
  source functions/zcolors >! zclrs.zsh
  ${PREFIX}sed -i "/^export -UT LS_COLORS ls_colors=/d" zclrs.zsh
}
_safe_one_off_load __my_zcolors_atclone_hook
