# https://github.com/junegunn/fzf

# junegunn/fzf - A command-line fuzzy finder
() {
  # Define the base URL for supporting files to keep the `dl` ice clean
  local fzf_base_url="https://raw.githubusercontent.com/junegunn/fzf/master"

  function __fzf_init_hook() {
    # Check also https://vitormv.github.io/fzf-themes/ and https://minsw.github.io/fzf-color-picker/

    export FZF_DEFAULT_OPTS="--color=bg+:-1,bg:-1,selected-bg:-1 \
      --pointer='▶' \
      --marker='✔' \
      --scrollbar='▌' \
      --border"

    # Define a global zsh variable
    typeset -gA FZF_DEFAULT_OPTS_CATPPUCCIN

    # From https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-latte.sh
    FZF_DEFAULT_OPTS_CATPPUCCIN[latte]="$FZF_DEFAULT_OPTS \
      --color=spinner:#DC8A78,hl:#D20F39,preview-bg:#EFF1F5, \
      --color=fg:#4C4F69,header:#D20F39,info:#8839EF,pointer:#7287FD \
      --color=marker:#7287FD,fg+:#4C4F69,prompt:#8839EF,hl+:#D20F39 \
      --color=border:#9CA0B0,label:#4C4F69,gutter:#EFF1F5"

    # From https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-frappe.sh
    FZF_DEFAULT_OPTS_CATPPUCCIN[frappe]="$FZF_DEFAULT_OPTS \
      --color=spinner:#F2D5CF,hl:#E78284,preview-bg:#232634, \
      --color=fg:#C6D0F5,header:#E78284,info:#CA9EE6,pointer:#BABBF1 \
      --color=marker:#BABBF1,fg+:#C6D0F5,prompt:#CA9EE6,hl+:#E78284 \
      --color=border:#737994,label:#C6D0F5,gutter:#303446"

    # From https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-macchiato.sh
    FZF_DEFAULT_OPTS_CATPPUCCIN[macchiato]="$FZF_DEFAULT_OPTS \
    --color=spinner:#F4DBD6,hl:#ED8796,preview-bg:#1E2030, \
    --color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#B7BDF8 \
    --color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 \
    --color=border:#6E738D,label:#CAD3F5,gutter:#24273A"

    # From https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-mocha.sh
    FZF_DEFAULT_OPTS_CATPPUCCIN[mocha]="$FZF_DEFAULT_OPTS \
      --color=spinner:#F5E0DC,hl:#F38BA8,preview-bg:#11111B, \
      --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#B4BEFE \
      --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
      --color=border:#6C7086,label:#CDD6F4,gutter:#1E1E2E"

    # Customization for fzf-completion (triggered by typing ** TAB)
    _fzf_compgen_path() { fd --hidden --follow --exclude .git . "$1" }
    _fzf_compgen_dir() { fd --type d --hidden --follow --exclude .git . "$1" }
    # Alt-c customization (cd widget)
    export FZF_ALT_C_COMMAND="fd -t d --hidden --follow --exclude .git"
    export FZF_ALT_C_OPTS="--preview '__zcompile_if_needed_and_source $DOTFILES_DIR/zinit/src/fzf-tab/__fzf_preview_file.zsh && __fzf_preview_file {}'"
    export FZF_DEFAULT_COMMAND='fd'
    
    # Source completions and key-bindings
    __zcompile_if_needed_and_source init.zsh
  }

  function __fzf_atclone_hook() {
    # Make the downloaded scripts executable
    chmod +x fzf-tmux fzf-preview.sh

    # Now that the files from `dl` exist, copy the man pages
    # Use -f to avoid errors if they already exist.
    cp -f fzf.1 "$ZPFX/man/man1/"
    cp -f fzf-tmux.1 "$ZPFX/man/man1/"
    
    # Generate completion and key-bindings scripts in one single file
    ./fzf --zsh > init.zsh
  }

  zinit ice from"gh-r" \
    dl"
      ${fzf_base_url}/bin/fzf-tmux;
      ${fzf_base_url}/bin/fzf-preview.sh;
      ${fzf_base_url}/man/man1/fzf.1;
      ${fzf_base_url}/man/man1/fzf-tmux.1;
    " \
    atclone'_safe_one_off_load __fzf_atclone_hook' \
    atpull"%atclone" \
    lbin"fzf -> fzf; fzf-tmux -> fzf-tmux; fzf-preview.sh -> fzf-preview;" \
    atinit'_safe_one_off_load __fzf_init_hook' \
    null lucid wait
  zinit light junegunn/fzf
}
