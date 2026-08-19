#!/bin/zsh -d

# ZAC_TMUX_CMD — tmux-server-resident appearance settings.
#
# This is the SUBSET of appearance state that lives in the running tmux server's
# memory and is therefore LOST on a server restart — unlike the on-disk config
# files and symlinks that zac-io-cmd writes, which persist across restarts.
#
# It is intentionally tiny and free of side effects beyond `tmux set-option`, so
# it is cheap to run both:
#   - on every appearance transition  (executed by zac-io-cmd), and
#   - on every tmux server start      (executed by tmux.conf via run-shell),
# the latter being what gives a fresh server the right config without re-doing
# zac-io-cmd's heavy global I/O (file rewrites, patina restart, …).
#
# Called as: zac-tmux-cmd <0|1>
#
# .zshenv is sourced automatically (no -f flag on the shebang), so DOTFILES_DIR
# and the bootstrap helpers are available. Requires FZF_DEFAULT_OPTS_CATPPUCCIN;
# sources the fzf atinit hook itself if a caller has not already populated it.
#
# Non-zero exit propagates to zac-io-cmd, which aborts the dispatch pipeline.

emulate -LR zsh
setopt extended_glob

local is_dark=${1:-}
[[ $is_dark == (0|1) ]] || {
  print -r -- "zac-tmux-cmd: invalid argument: '${is_dark}' (expected 0 or 1)" >&2
  exit 1
}

# Ensure the catppuccin fzf option strings are available (idempotent — skipped
# when a caller such as zac-io-cmd has already sourced the hook in this process).
(( ${+FZF_DEFAULT_OPTS_CATPPUCCIN} )) || \
  __zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/fzf/__fzf_atinit_hook.zsh"

# The appearance flag itself.
#
# Since zsh-appearance-control 2.0.0, bin/appearance-dispatch no longer sets
# @dark_appearance: tmux is a consumer like any other tool. The catppuccin theme
# reads this option, so we own it here — in the one helper that runs both on a
# transition and at tmux server start.
tmux set-option -gq @dark_appearance "$is_dark"

if (( is_dark )); then
  # tmux-fzf-links
  tmux set-option -g @fzf-links-fzf-display-options "$(printf '%s' "${FZF_DEFAULT_OPTS_CATPPUCCIN[frappe]}" | sed -E 's/--border(=[^[:space:]]+)?[[:space:]]*//g') --color=preview-bg:#232634,gutter:#232634 -w 100% --maxnum-displayed 20 --multi --track --no-preview"
else
  # tmux-fzf-links
  tmux set-option -g @fzf-links-fzf-display-options "$(printf '%s' "${FZF_DEFAULT_OPTS_CATPPUCCIN[latte]}" | sed -E 's/--border(=[^[:space:]]+)?[[:space:]]*//g') --color=preview-bg:#dce0e8,gutter:#dce0e8 -w 100% --maxnum-displayed 20 --multi --track --no-preview"
fi
