#!/bin/zsh -d

# ZAC_IO_CMD — heavy I/O for appearance changes.
#
# Called by appearance-dispatch as: zac-io-cmd <0|1>
#
# .zshenv is sourced automatically (no -f flag on the shebang), so DOTFILES_DIR,
# XDG_CONFIG_HOME, and XDG_STATE_HOME are available.
#
# Non-zero exit aborts the dispatch pipeline (no ground truth written, no USR1 sent).

emulate -LR zsh
setopt extended_glob

local is_dark=${1:-}
[[ $is_dark == (0|1) ]] || {
  print -r -- "zac-io-cmd: invalid argument: '${is_dark}' (expected 0 or 1)" >&2
  exit 1
}

# ls_colors symlink — points to the active appearance file
local vivid_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/vivid"

# fzf default config
__zcompile_if_needed_and_source $DOTFILES_DIR/zinit/src/fzf/__fzf_atinit_hook.zsh

if (( is_dark )); then
  # yazi
  sed -E 's/^(dark|light)[[:space:]]*=.*$/\1 = "catppuccin-frappe"/' \
    "$DOTFILES_DIR/.config/yazi/theme.toml" > "$XDG_CONFIG_HOME/yazi/theme.toml" || exit 1

  # gemini
  sed -E 's/^([[:space:]]*\"theme\")[[:space:]]*\:.*$/\1\: "Default Dark"/' \
    "$DOTFILES_DIR/.config/gemini/settings.json" > "$HOME/.gemini/settings.json" || exit 1

  # claude
  sed -E 's/^([[:space:]]*"theme"[[:space:]]*:[[:space:]]*")[^"]*(".*)/\1dark-ansi\2/' \
    "$HOME/.claude.json" > "$HOME/.claude.json.tmp" && \
    mv "$HOME/.claude.json.tmp" "$HOME/.claude.json" || exit 1

  # opencode
  sed -E 's/^([[:space:]]*"theme_mode"[[:space:]]*:[[:space:]]*")[^"]*(".*)/\1dark\2/' \
    "$XDG_STATE_HOME/opencode/kv.json" | \
    sed -E 's/^([[:space:]]*"theme"[[:space:]]*:[[:space:]]*")[^"]*(".*)/\1catppuccin-frappe\2/' \
    > "$XDG_STATE_HOME/opencode/kv.json.tmp" && \
    mv "$XDG_STATE_HOME/opencode/kv.json.tmp" "$XDG_STATE_HOME/opencode/kv.json" || exit 1

  # IPython
  sed -E "s/^[[:space:]]*c\.InteractiveShell\.colors[[:space:]]*=[[:space:]]*.*$/c.InteractiveShell.colors = 'linux'/" \
    "$DOTFILES_DIR/ipython/profile_default/ipython_config.py" | \
    sed -E "s/^[[:space:]]*c\.TerminalInteractiveShell\.colors[[:space:]]*=[[:space:]]*.*$/c.TerminalInteractiveShell.colors = 'linux'/" \
        > "$HOME/.ipython/profile_default/ipython_config.py"

  # patina
  sed -E 's/^([[:space:]]*theme[[:space:]]*=[[:space:]]*).*$/\1"nord"/' \
      "$DOTFILES_DIR/.config/zsh-patina/config.toml" > "$HOME/.config/zsh-patina/config.toml" && patina restart || exit 1

  # LS_COLORS for tmux-fzf-links
  ln -sf -- "ls_colors_dark" "$vivid_cache_dir/ls_colors" || exit 1

  # tmux-fzf-links
  tmux set-option -g @fzf-links-fzf-display-options "$(printf '%s' "$FZF_DEFAULT_OPTS" | sed -E 's/--border(=[^[:space:]]+)?[[:space:]]*//g') --color=preview-bg:#232634,gutter:#232634 -w 100% --maxnum-displayed 20 --multi --track --no-preview"
  
else
  # yazi
  sed -E 's/^(dark|light)[[:space:]]*=.*$/\1 = "catppuccin-latte"/' \
    "$DOTFILES_DIR/.config/yazi/theme.toml" > "$XDG_CONFIG_HOME/yazi/theme.toml" || exit 1

  # gemini
  sed -E 's/^([[:space:]]*\"theme\")[[:space:]]*\:.*$/\1\: "Default Light"/' \
    "$DOTFILES_DIR/.config/gemini/settings.json" > "$HOME/.gemini/settings.json" || exit 1

  # claude
  sed -E 's/^([[:space:]]*"theme"[[:space:]]*:[[:space:]]*")[^"]*(".*)/\1light-ansi\2/' \
    "$HOME/.claude.json" > "$HOME/.claude.json.tmp" && \
    mv "$HOME/.claude.json.tmp" "$HOME/.claude.json" || exit 1

  # opencode
  sed -E 's/^([[:space:]]*"theme_mode"[[:space:]]*:[[:space:]]*")[^"]*(".*)/\1light\2/' \
    "$XDG_STATE_HOME/opencode/kv.json" | \
    sed -E 's/^([[:space:]]*"theme"[[:space:]]*:[[:space:]]*")[^"]*(".*)/\1catppuccin\2/' \
    > "$XDG_STATE_HOME/opencode/kv.json.tmp" && \
    mv "$XDG_STATE_HOME/opencode/kv.json.tmp" "$XDG_STATE_HOME/opencode/kv.json" || exit 1

  # IPython
  sed -E "s/^[[:space:]]*c\.InteractiveShell\.colors[[:space:]]*=[[:space:]]*.*$/c.InteractiveShell.colors = 'lightbg'/" \
    "$DOTFILES_DIR/ipython/profile_default/ipython_config.py" | \
    sed -E "s/^[[:space:]]*c\.TerminalInteractiveShell\.colors[[:space:]]*=[[:space:]]*.*$/c.TerminalInteractiveShell.colors = 'lightbg'/" \
    > "$HOME/.ipython/profile_default/ipython_config.py"

  # patina
  sed -E 's/^([[:space:]]*theme[[:space:]]*=[[:space:]]*).*$/\1"classic"/' \
      "$DOTFILES_DIR/.config/zsh-patina/config.toml" > "$HOME/.config/zsh-patina/config.toml" && patina restart || exit 1

  
  
  # LS_COLORS for tmux-fzf-links
  ln -sf -- "ls_colors_light" "$vivid_cache_dir/ls_colors" || exit 1

  # tmux-fzf-links
  tmux set-option -g @fzf-links-fzf-display-options "$(printf '%s' "$FZF_DEFAULT_OPTS" | sed -E 's/--border(=[^[:space:]]+)?[[:space:]]*//g') --color=preview-bg:#dce0e8,gutter:#dce0e8 -w 100% --maxnum-displayed 20 --multi --track --no-preview"
fi
