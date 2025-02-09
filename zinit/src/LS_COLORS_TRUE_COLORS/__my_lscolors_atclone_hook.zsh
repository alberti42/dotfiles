#!/hint/zsh

function __my_lscolors_atclone_hook() {
  # If dircolors is not found, then consider the darwin variant with prefix
  [[ -n ${commands[gsed]} ]] && local PREFIX=${${(M)OSTYPE##darwin}:+g}

  ${PREFIX}sed -i  "/^DIR\s/c\DIR 38;2;104;114;255;1" LS_COLORS_TRUE   # adjusts the color of directories
  ${PREFIX}sed -i "/^LINK\s/c\LINK 1;36" LS_COLORS_TRUE   # adjusts the color of soft links (alternative -> TARGET)
  ${PREFIX}dircolors -b LS_COLORS >! src_colors.zsh
  ${PREFIX}dircolors -b LS_COLORS_TRUE >! src_true_colors.zsh

  if [[ $OSTYPE =~ 'darwin*' ]]; then
    echo -e "LSCOLORS=exfxcxdxbxegedabagacad\nexport LSCOLORS" >> src_colors.zsh
    echo -e "LSCOLORS=exfxcxdxbxegedabagacad\nexport LSCOLORS" >> src_true_colors.zsh
  fi
}
_safe_one_off_load __my_lscolors_atclone_hook
