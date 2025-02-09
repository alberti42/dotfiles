# https://github.com/alberti42/LS_COLORS_TRUE_COLORS

# Determine which variant to source
local src_file
if [[ "$COLORTERM" == *truecolor* || "$COLORTERM" == *24bit* ]]; then
    # this terminal supports truecolor
    src_file=src_true_colors.zsh
else
    # Truecolor is not supported
    src_file=src_colors.zsh
fi

# LS_COLORS theme - download the default profile
zinit ice depth=1 wait light-mode lucid \
    atclone"source '${${(%):-%x}:h}/__my_lscolors_atclone_hook.zsh'" \
    atpull'%atclone' \
    git \
    id-as'LS_COLORS_TRUE_COLORS' \
    lucid \
    compile:'*.zsh' \
    src:"$src_file" \
    nocompile'!'
zinit light @alberti42/LS_COLORS_TRUE_COLORS
