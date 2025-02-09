# https://github.com/zdharma-continuum/fast-syntax-highlighting

function __fsh_atload_hook() {
  # `overlay.ini` -> file defining a set of styles to overlay an already configured theme;
  # `fast-theme` processes `overlay.ini` and creates a new configuration script stored in the cache folder `$FAST_WORK_DIR`
  # check https://github.com/zdharma-continuum/fast-syntax-highlighting/blob/master/THEME_GUIDE.md
  
  # Define file paths
  local overlay_zsh="$FAST_WORK_DIR/theme_overlay.zsh"
  local overlay_ini="$DOTFILES_DIR/.config/fsh/overlay.ini"

  # Flag to indicate whether the ini file needs to be processed
  local process_ini=0

  # Exit if no overlay.ini was provided
  if [ ! -f "$overlay_ini" ]; then
    exit 0
  fi

  # Force process_ini if overlay_zsh does not exist
  if [ ! -f "$overlay_zsh" ]; then
    process_ini=1
  fi
  
  # Compare modification times
  if [[ $process_ini -ne 0 || "$overlay_ini" -nt "$overlay_zsh" ]]; then
    source "${${(%):-%x}:h}/__generate_overlay_fsh.zsh"
  fi

  # Configure how zsh highlighting behaves when text is pasted into zle
  # Choose zle_highlight=('paste:none') to disable highlighting
  zle_highlight=('paste:fg=#00E5FF,bg=#002B36')
}
 
# Load syntax highlightin (plugin must be loaded after plugins issuing compdef)
zinit ice wait depth=1 light-mode lucid \
  atinit'
    ZINIT[COMPINIT_OPTS]=-C
    zicompinit
    zicdreplay' \
  blockf \
  atload'_safe_one_off_load __fsh_atload_hook'
  
zinit light zdharma-continuum/fast-syntax-highlighting
