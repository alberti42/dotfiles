# https://github.com/junegunn/fzf

# For keybinding, add the ICE: src'key-bindings.zsh'
zinit ice \
  binary \
  atclone"source '${${(%):-%x}:h}/__fzf_atclone_hook.zsh'" \
  atpull'%atclone' \
  depth=1 \
  lucid \
  wait \
  nocompile \
  src'shell/init.zsh' \
  lbin'bin/fzf -> fzf; bin/fzf-tmux -> fzf-tmux; bin/fzf-preview.sh -> fzf-preview'
zinit light @junegunn/fzf

# Alternative downloading the binary from the latest release

# zinit for \
# binary \
# dl="
#   https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/shell/key-bindings.zsh;
#   https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/shell/completion.zsh -> $ZPFX/share/fzf/completion.zsh;
#   https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/bin/fzf-preview.sh -> fzf-preview;
#   https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/bin/fzf-tmux -> fzf-tmux;
#   https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/man/man1/fzf.1 -> $ZPFX/share/man/man1/fzf.1;
#   https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/man/man1/fzf-tmux.1 -> $ZPFX/share/man/man1/fzf-tmux.1;
#   " \
# from'gh-r' \
# nocompletions \
# nocompile \
# pick'$ZPFX/bin/fzf; fzf-tmux; fzf-preview' \
# lbin'fzf -> fzf; fzf-tmux -> fzf-tmux; fzf-preview -> fzf-preview' \
# @junegunn/fzf
