# https://github.com/tmux/tmux

zinit ice \
  binary \
  lbin'tmux -> tmux' \
  atclone"source '${${(%):-%x}:h}/__tmux_atclone_hook.zsh'" \
  atpull'%atclone' \
  depth=1 \
  lucid \
  nocompletions \
  nocompile
zinit light @tmux/tmux