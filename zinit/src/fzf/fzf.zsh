# https://github.com/junegunn/fzf

# Generated with https://minsw.github.io/fzf-color-picker/
# local __FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' --color=fg:#d0d0d0,bg:#121212,hl:#5f87af --color=fg+:#d0d0d0,bg+:#262626,hl+:#5fd7ff --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff --color=marker:#87ff00,spinner:#af5fff,header:#87afaf'

# From https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-latte.sh
local __FZF_DEFAULT_OPTS_LATTE="$FZF_DEFAULT_OPTS \
  --color=bg+:#CCD0DA,bg:#EFF1F5,spinner:#DC8A78,hl:#D20F39 \
  --color=fg:#4C4F69,header:#D20F39,info:#8839EF,pointer:#DC8A78 \
  --color=marker:#7287FD,fg+:#4C4F69,prompt:#8839EF,hl+:#D20F39 \
  --color=selected-bg:#BCC0CC \
  --color=border:#9CA0B0,label:#4C4F69"

# From https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-frappe.sh
local __FZF_DEFAULT_OPTS_FRAPPE="$FZF_DEFAULT_OPTS \
  --color=bg+:#414559,bg:#303446,spinner:#F2D5CF,hl:#E78284 \
  --color=fg:#C6D0F5,header:#E78284,info:#CA9EE6,pointer:#F2D5CF \
  --color=marker:#BABBF1,fg+:#C6D0F5,prompt:#CA9EE6,hl+:#E78284 \
  --color=selected-bg:#51576D \
  --color=border:#737994,label:#C6D0F5"

# From https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-macchiato.sh
local __FZF_DEFAULT_OPTS_MACCHIATO="$FZF_DEFAULT_OPTS \
--color=bg+:#363A4F,bg:#24273A,spinner:#F4DBD6,hl:#ED8796 \
--color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 \
--color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 \
--color=selected-bg:#494D64 \
--color=border:#6E738D,label:#CAD3F5"

# From https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-mocha.sh
local __FZF_DEFAULT_OPTS_MOCHA="$FZF_DEFAULT_OPTS \
  --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
  --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
  --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
  --color=selected-bg:#45475A \
  --color=border:#6C7086,label:#CDD6F4"

# For keybinding, add the ICE: src'key-bindings.zsh'
zinit ice \
  binary \
  atclone"source '${${(%):-%x}:h}/__fzf_atclone_hook.zsh'" \
  atpull'%atclone' \
  atinit"local __is_dark=\$(is_dark_appearance)
  if [[ \$__is_dark = "1" ]]; then
    export FZF_DEFAULT_OPTS=\"$__FZF_DEFAULT_OPTS_MOCHA\"
  else
    export FZF_DEFAULT_OPTS=\"$__FZF_DEFAULT_OPTS_MACCHIATO\"
  fi" \
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
