# Plugin binding GNU coreutils to their default names
# Useful in systems that don't have GNU coreutils available by default
#
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/gnu-utils

if [[ $OSTYPE =~ 'darwin*' ]]; then
  zinit depth=1 null wait lucid light-mode \
    src:'OMZP::gnu-utils' \
    atclone"source '${${(%):-%x}:h}/__gnu_utils_atclone.zsh'" \
    for @OMZP::gnu-utils
fi
