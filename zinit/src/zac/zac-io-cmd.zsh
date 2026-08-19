#!/bin/zsh -d

# ZAC_IO_CMD — heavy I/O for appearance changes.
#
# Called by appearance-dispatch as: zac-io-cmd <0|1>
#
# .zshenv is sourced automatically (no -f flag on the shebang), so DOTFILES_DIR,
# XDG_CONFIG_HOME, and XDG_STATE_HOME are available.
#
# Non-zero exit aborts the dispatch pipeline (no ground truth written, no USR1
# sent), so this script must fail ONLY on a real error.
#
# A consumer that is not installed on this host is NOT an error. The same
# dotfiles are used on machines with different tools — a Linux box with no
# claude, no opencode, no tmux server — and an absent config file used to abort
# the whole pipeline, leaving every shell on that host with no appearance at all.
# Missing files are therefore skipped with a note; only a failing rewrite or a
# failing tool aborts.
#
# The two appearances differ only in a handful of values, so they are chosen
# once into variables and applied by a single sequence of calls. The previous
# version duplicated every command in an if/else and the two copies had already
# drifted (the light btop rule had lost its `^` anchor).

emulate -LR zsh
setopt extended_glob
zmodload -F zsh/stat b:zstat 2>/dev/null

local is_dark=${1:-}
[[ $is_dark == (0|1) ]] || {
  print -r -- "zac-io-cmd: invalid argument: '${is_dark}' (expected 0 or 1)" >&2
  exit 1
}

# --- helpers -----------------------------------------------------------------

# Rewrite a config file in place with sed.
#
# Usage: _rewrite <file> -e <expr> [-e <expr> …]
# Returns 0 when rewritten, 2 when the file is absent (skipped), 1 on error.
function _rewrite() {
  local file=$1; shift

  if [[ ! -f $file ]]; then
    print -r -- "zac-io-cmd: skipping, not present: $file"
    return 2
  fi

  local tmp="${file}.zac.tmp"

  if ! sed -E "$@" "$file" > "$tmp"; then
    rm -f "$tmp"
    print -r -- "zac-io-cmd: sed failed: $file" >&2
    return 1
  fi

  # Keep the original mode: the rewrite goes through a temp file, so without
  # this the file would come back with whatever the umask says, and
  # ~/.claude.json (which holds credentials) is deliberately 0600.
  #
  # `zstat -o` prints the mode in octal (0100600); the last four digits are the
  # permission bits. Do NOT compute this arithmetically: in zsh arithmetic a
  # leading zero is not octal unless OCTAL_ZEROES is set, so `mode & 07777`
  # ANDs against decimal 7777 and yields 0 for a 0600 file — which is a
  # `chmod 0`, and cost an afternoon once.
  local mode
  if mode=$(zstat -o +mode "$file" 2>/dev/null) && [[ ${mode[-4,-1]} == <-> ]]; then
    chmod ${mode[-4,-1]} "$tmp" || {
      rm -f "$tmp"
      print -r -- "zac-io-cmd: cannot set mode on: $file" >&2
      return 1
    }
  fi

  if ! mv "$tmp" "$file"; then
    rm -f "$tmp"
    print -r -- "zac-io-cmd: cannot replace: $file" >&2
    return 1
  fi

  return 0
}

# Point a symlink at a target, when the containing directory exists.
#
# Returns 0 when linked, 2 when skipped, 1 on error.
function _relink() {
  local target=$1 link=$2

  if [[ ! -d ${link:h} ]]; then
    print -r -- "zac-io-cmd: skipping, no directory: ${link:h}"
    return 2
  fi
  # A relative target is resolved against the link's directory.
  if [[ $target == /* && ! -e $target ]]; then
    print -r -- "zac-io-cmd: skipping, no target: $target"
    return 2
  fi

  ln -sfn "$target" "$link" || {
    print -r -- "zac-io-cmd: cannot link $link -> $target" >&2
    return 1
  }
  return 0
}

# --- the two appearances -----------------------------------------------------

local yazi_theme gemini_theme claude_theme opencode_mode opencode_theme \
      ipython_colors patina_theme ls_colors_file btop_theme git_theme

if (( is_dark )); then
  yazi_theme=catppuccin-frappe
  gemini_theme="Default Dark"
  claude_theme=dark-ansi
  opencode_mode=dark
  opencode_theme=catppuccin-frappe
  ipython_colors=linux
  patina_theme=nord
  ls_colors_file=ls_colors_dark
  btop_theme=catppuccin_frappe
  git_theme=theme-dark.gitconfig
else
  yazi_theme=catppuccin-latte
  gemini_theme="Default Light"
  claude_theme=light-ansi
  opencode_mode=light
  opencode_theme=catppuccin
  ipython_colors=lightbg
  patina_theme=classic
  ls_colors_file=ls_colors_light
  btop_theme=catppuccin_latte
  git_theme=theme-light.gitconfig
fi

# --- apply -------------------------------------------------------------------
#
# Every step: 0 = done, 2 = skipped (not installed here), 1 = abort.

# yazi
_rewrite "$DOTFILES_DIR/.config/yazi/theme.toml" \
  -e 's/^(dark|light)[[:space:]]*=.*$/\1 = "'"$yazi_theme"'"/' || (( $? == 2 )) || exit 1

# gemini
_rewrite "$DOTFILES_DIR/.config/gemini/settings.json" \
  -e 's/^([[:space:]]*"theme")[[:space:]]*:.*$/\1: "'"$gemini_theme"'"/' || (( $? == 2 )) || exit 1

# claude
_rewrite "$HOME/.claude.json" \
  -e 's/^([[:space:]]*"theme"[[:space:]]*:[[:space:]]*")[^"]*(".*)/\1'"$claude_theme"'\2/' || (( $? == 2 )) || exit 1

# opencode
_rewrite "$XDG_STATE_HOME/opencode/kv.json" \
  -e 's/^([[:space:]]*"theme_mode"[[:space:]]*:[[:space:]]*")[^"]*(".*)/\1'"$opencode_mode"'\2/' \
  -e 's/^([[:space:]]*"theme"[[:space:]]*:[[:space:]]*")[^"]*(".*)/\1'"$opencode_theme"'\2/' || (( $? == 2 )) || exit 1

# IPython
_rewrite "$DOTFILES_DIR/ipython/profile_default/ipython_config.py" \
  -e "s/^[[:space:]]*c\.InteractiveShell\.colors[[:space:]]*=[[:space:]]*.*\$/c.InteractiveShell.colors = '$ipython_colors'/" \
  -e "s/^[[:space:]]*c\.TerminalInteractiveShell\.colors[[:space:]]*=[[:space:]]*.*\$/c.TerminalInteractiveShell.colors = '$ipython_colors'/" \
  || (( $? == 2 )) || exit 1

# patina — restart only when its config was actually rewritten, and only when
# the binary is on this host.
_rewrite "$DOTFILES_DIR/.config/zsh-patina/config.toml" \
  -e 's/^([[:space:]]*theme[[:space:]]*=[[:space:]]*).*$/\1"'"$patina_theme"'"/'
case $? in
  0) if (( $+commands[patina] )); then
       patina restart || { print -r -- "zac-io-cmd: patina restart failed" >&2; exit 1 }
     else
       print -r -- "zac-io-cmd: skipping, not installed: patina"
     fi ;;
  2) ;;
  *) exit 1 ;;
esac

# LS_COLORS for tmux-fzf-links (vivid cache, populated by the vivid snippet)
_relink "$ls_colors_file" "${XDG_CACHE_HOME:-$HOME/.cache}/vivid/ls_colors" || (( $? == 2 )) || exit 1

# btop
_rewrite "$DOTFILES_DIR/.config/btop/btop.conf" \
  -e 's/^(color_theme[[:space:]]*=[[:space:]]*").*"$/\1'"$btop_theme"'"/' || (( $? == 2 )) || exit 1

# git CLI
_relink "$DOTFILES_DIR/.config/git/$git_theme" "$XDG_CONFIG_HOME/git/theme.gitconfig" \
  || (( $? == 2 )) || exit 1

# tmux-server-resident settings (@dark_appearance and the @fzf-links-* option),
# which a fresh tmux server loses on restart. Delegated to a small co-located
# helper that tmux.conf also runs at server start, so the value has a single
# source of truth.
#
# Skipped when there is no server to talk to: `tmux set-option` does not start
# one, and on a host without a running tmux (or without tmux at all) this used
# to be the last command and therefore the exit status of the whole script.
if (( $+commands[tmux] )) && tmux has-session 2>/dev/null; then
  "${${(%):-%x}:a:h}/zac-tmux-cmd.zsh" "$is_dark" || exit 1
else
  print -r -- "zac-io-cmd: skipping, no tmux server: zac-tmux-cmd.zsh"
fi

exit 0
