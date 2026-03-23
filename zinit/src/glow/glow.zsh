# https://github.com/charmbracelet/glow

zinit ice \
    null \
    wait'0b' \
    lucid \
    from'gh-r' \
    nocompile \
    completions \
    atclone"source '${${(%):-%x}:a:h}/__glow_atclone_hook.zsh'" \
    atpull'%atclone' \
    lbin'glow -> glow'
zinit light @charmbracelet/glow
