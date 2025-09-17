# Import neovim
# https://github.com/neovim/neovim

zinit ice \
  binary \
  depth=1 \
  lucid \
  from'gh-r' \
  lbin'tree-sitter-* -> tree-sitter' \
  nocompletions \
  nocompile
zinit light @tree-sitter/tree-sitter

local __bpick
if [[ $OSTYPE =~ 'darwin*' ]]; then
  __bpick='nvim-macos-*.tar.gz'
else
  __bpick='nvim-linux-*.tar.gz'
fi

zinit ice \
  binary \
  lbin'neovim_shim.zsh -> nvim' \
  bpick"${__bpick}" \
  atclone"source '${${(%):-%x}:h}/__neovim_atclone_hook.zsh'" \
  atpull'%atclone' \
  depth=1 \
  lucid \
  from'gh-r' \
  nocompletions \
  nocompile
zinit light @neovim/neovim
