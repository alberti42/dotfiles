# https://github.com/charmbracelet/glow

function __glow_init_hook() {

}

zinit ice \
    null \
    wait'0a' \
    lucid \
    from'gh-r' \
    atinit'_safe_one_off_load __glow_init_hook' \
    nocompile \
    completions \
    atclone"source '${${(%):-%x}:a:h}/__glow_atclone_hook.zsh'" \
    atpull'%atclone' \
    lbin'glow -> glow'
zinit light @charmbracelet/glow
