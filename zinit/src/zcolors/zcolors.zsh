# https://github.com/marlonrichert/zcolors

# zcolors - extend the color theme of LS_COLORS to the other GNU commands
zinit ice wait'0b' light-mode lucid \
    atclone"source '${${(%):-%x}:a:h}/__my_zcolors_atclone_hook.zsh'" \
    atpull'%atclone' \
    git id-as'marlonrichert/zcolors' nocompile'!' \
    compile:'zclrs.zsh' src'zclrs.zsh' reset
zinit light @marlonrichert/zcolors

