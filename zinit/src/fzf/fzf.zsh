# https://github.com/junegunn/fzf

# Generated with https://minsw.github.io/fzf-color-picker/
# local __FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' --color=fg:#d0d0d0,bg:#121212,hl:#5f87af --color=fg+:#d0d0d0,bg+:#262626,hl+:#5fd7ff --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff --color=marker:#87ff00,spinner:#af5fff,header:#87afaf'

# From https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-latte.sh
local __FZF_DEFAULT_OPTS_LATTE="$FZF_DEFAULT_OPTS \
  --color=bg+:-1,bg:-1,spinner:#DC8A78,hl:#D20F39 \
  --color=fg:#4C4F69,header:#D20F39,info:#8839EF,pointer:#DC8A78 \
  --color=marker:#7287FD,fg+:#4C4F69,prompt:#8839EF,hl+:#D20F39 \
  --color=selected-bg:-1 \
  --color=border:#9CA0B0,label:#4C4F69"

# From https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-frappe.sh
local __FZF_DEFAULT_OPTS_FRAPPE="$FZF_DEFAULT_OPTS \
  --color=bg+:-1,bg:-1,spinner:#F2D5CF,hl:#E78284 \
  --color=fg:#C6D0F5,header:#E78284,info:#CA9EE6,pointer:#F2D5CF \
  --color=marker:#BABBF1,fg+:#C6D0F5,prompt:#CA9EE6,hl+:#E78284 \
  --color=selected-bg:-1 \
  --color=border:#737994,label:#C6D0F5"

# From https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-macchiato.sh
local __FZF_DEFAULT_OPTS_MACCHIATO="$FZF_DEFAULT_OPTS \
--color=bg+:-1,bg:-1,spinner:#F4DBD6,hl:#ED8796 \
--color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 \
--color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 \
--color=selected-bg:-1 \
--color=border:#6E738D,label:#CAD3F5"

# From https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-mocha.sh
local __FZF_DEFAULT_OPTS_MOCHA="$FZF_DEFAULT_OPTS \
  --color=bg+:-1,bg:-1,spinner:#F5E0DC,hl:#F38BA8 \
  --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
  --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
  --color=selected-bg:-1 \
  --color=border:#6C7086,label:#CDD6F4"

# junegunn/fzf - A command-line fuzzy finder
() {
  # Define the base URL for supporting files to keep the `dl` ice clean
  local fzf_base_url="https://raw.githubusercontent.com/junegunn/fzf/master"

  function __fzf_init_hook() {
    local __is_dark=$(is_dark_appearance)
    if [[ $__is_dark = "1" ]]; then
      export FZF_DEFAULT_OPTS="$__FZF_DEFAULT_OPTS_MOCHA"
    else
      export FZF_DEFAULT_OPTS="$__FZF_DEFAULT_OPTS_MACCHIATO"
    fi
  }

  function __fzf_apull_hook() {
    # Make the downloaded scripts executable
    chmod +x fzf-tmux fzf-preview.sh

    # Now that the files from `dl` exist, copy the man pages
    # Use -f to avoid errors if they already exist.
    cp -f fzf.1 "$ZPFX/man/man1/"
    cp -f fzf-tmux.1 "$ZPFX/man/man1/"
  }

  zinit ice from"gh-r" \
    dl"
      ${fzf_base_url}/shell/completion.zsh;
      ${fzf_base_url}/bin/fzf-tmux;
      ${fzf_base_url}/bin/fzf-preview.sh;
      ${fzf_base_url}/man/man1/fzf.1;
      ${fzf_base_url}/man/man1/fzf-tmux.1;
    " \
    atpull'_safe_one_off_load __fzf_apull_hook' \
    lbin"fzf -> fzf; fzf-tmux -> fzf-tmux; fzf-preview.sh -> fzf-preview;" \
    atinit'_safe_one_off_load __fzf_init_hook' \
    src'completion.zsh' \
    null lucid wait
  zinit light junegunn/fzf
}
