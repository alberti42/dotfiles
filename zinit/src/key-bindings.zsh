#!/hint/zsh

# man zshzle; note: the key bindings are case sensitive!
# for other key bindings check: https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/refs/heads/master/lib/key-bindings.zsh

# Ensures that zsh/terminfo is loaded
zmodload zsh/terminfo

# Ensure that zsh/complist module is loaded: it provides the menuselect UI,
# scrolling lists (where list-prompt applies), and the menu-select/reverse-menu-select widgets.
# It often gets loaded automatically the first time completion needs it (e.g. when you use menu
# select or certain listing behaviors).
zmodload -i zsh/complist


# Bind to arrow keys
autoload -Uz up-line-or-beginning-search
zle -N up-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search  # Up arrow
bindkey "^[OA" up-line-or-beginning-search  # Up arrow
autoload -Uz down-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search  # Down arrow
bindkey "^[OB" down-line-or-beginning-search  # Down arrow

bindkey -e # Enable emacs key bindings
bindkey "^p"       up-line-or-beginning-search
bindkey "^n"       down-line-or-beginning-search
bindkey "^[f"      emacs-forward-word
bindkey "^[b"      emacs-backward-word

# Bind Meta-Left and Meta-Right dynamically
if [[ -n "${terminfo[kRIT]}" ]]; then
  bindkey -M emacs "${terminfo[kRIT]}" emacs-forward-word
else
  bindkey -M emacs "^[^[[C" emacs-forward-word
fi
if [[ -n "${terminfo[kLFT]}" ]]; then
  bindkey -M emacs "${terminfo[kLFT]}" emacs-backward-word
else
  bindkey -M emacs "^[^[[D" emacs-backward-word
fi
# Standard CSI sequences for Alt+Left/Right (WezTerm without remapping)
bindkey -M emacs '\e[1;3C' emacs-forward-word
bindkey -M emacs '\e[1;3D' emacs-backward-word

# Bind delete key to deleting character at the cursor position
if [[ -n "${terminfo[kdch1]}" ]]; then
  bindkey -M emacs "${terminfo[kdch1]}" delete-char
else
  bindkey -M emacs "^[[3~" delete-char
fi

# Fixes a problem with Terminus which does not have the right
# description of terminfo `infocmp -L -1`
if [[ $TERM_PROGRAM == "Terminus-Sublime" ]]; then
  # Alt + Right Arrow Key
  bindkey -M emacs "\e[1;3C"   emacs-forward-word
  # Alt + Left Arrow Key
  bindkey -M emacs "\e[1;3D"   emacs-backward-word
fi

# Home key: Beginning of line
if [[ -n "${terminfo[khome]}" ]]; then
  bindkey "${terminfo[khome]}" beginning-of-line
else
  bindkey "^[[H" beginning-of-line  # Fallback for Home key
fi

# End key: End of line
if [[ -n "${terminfo[kend]}" ]]; then
  bindkey "${terminfo[kend]}" end-of-line
else
  bindkey "^[[F" end-of-line        # Fallback for End key
fi

# PageUp key: Scroll up in history
if [[ -n "${terminfo[kpp]}" ]]; then
  bindkey "${terminfo[kpp]}" up-line-or-history
else
  bindkey "^[[5~" up-line-or-history  # Fallback for PageUp
fi

# PageDown key: Scroll down in history
if [[ -n "${terminfo[knp]}" ]]; then
  bindkey "${terminfo[knp]}" down-line-or-history
else
  bindkey "^[[6~" down-line-or-history  # Fallback for PageDown
fi

# Configure Tab and Shift-Tab dynamically
# move through the completion menu forward and backward (only relevant for `menu select`)
if [[ -n "${terminfo[ht]}" ]]; then # Tab key via terminfo
  bindkey "${terminfo[ht]}" menu-complete         # menu select
else  # Default fallback for Tab
  bindkey "^I" menu-complete                      # menu select
fi
if [[ -n "${terminfo[kcbt]}" ]]; then # Shift-Tab via terminfo
  bindkey "${terminfo[kcbt]}" reverse-menu-complete
else # Fallback for Shift-Tab
  bindkey "^[[Z" reverse-menu-complete    
fi
# PageUp / PageDown in menuselect
if [[ -n ${terminfo[kpp]-} ]]; then
  bindkey -M menuselect "${terminfo[kpp]}" backward-word
else
  bindkey -M menuselect "^[[5~" backward-word
fi
if [[ -n ${terminfo[knp]-} ]]; then
  bindkey -M menuselect "${terminfo[knp]}" forward-word
else
  bindkey -M menuselect "^[[6~" forward-word
fi
# Home / End in menuselect (top / bottom)
if [[ -n ${terminfo[khome]-} ]]; then
  bindkey -M menuselect "${terminfo[khome]}" beginning-of-history
else
  bindkey -M menuselect "^[[H" beginning-of-history   # common Home
  bindkey -M menuselect "^[[1~" beginning-of-history  # xterm Home
  bindkey -M menuselect "^[OH" beginning-of-history   # rxvt/Home
fi
if [[ -n ${terminfo[kend]-} ]]; then
  bindkey -M menuselect "${terminfo[kend]}" end-of-history
else
  bindkey -M menuselect "^[[F" end-of-history         # common End
  bindkey -M menuselect "^[[4~" end-of-history        # xterm End
  bindkey -M menuselect "^[OF" end-of-history         # rxvt/End
fi

bindkey "^d"       delete-char
bindkey "^[d"      delete-word

# Define a widget to cancel the mark
function emacs-cancel-mark() {
  if [[ $REGION_ACTIVE -eq 1 ]]; then
    # Deactivate the mark
    zle set-mark-command -n -1
  else
    # C-g
    zle send-break
  fi
}
zle -N emacs-cancel-mark

# Unbind CTRL-s for history-incremental-search-forward
bindkey -r '^S'

# Bind to CTRL-g
bindkey -M emacs "^g" emacs-cancel-mark

# Copy the current zsh region to the macOS clipboard
function __copy_to_clipboard() {
  if command -v pbcopy &>/dev/null; then
    # macOS
    print -rn -- "$1" | pbcopy
  elif command -v xclip &>/dev/null; then
    # linux
    print -rn -- "$1" xclip -selection clipboard
  fi
}
function __paste_from_clipboard() {
  if command -v pbpaste &>/dev/null; then
    # macOS
    pbpaste
  elif command -v xclip &>/dev/null; then
    # linux
    xclip -selection clipboard -o
  fi
}
function x-kill-region() {
  zle kill-region
  __copy_to_clipboard "$CUTBUFFER"
}
function x-copy-region-as-kill() {
  zle copy-region-as-kill
  __copy_to_clipboard "$CUTBUFFER"
}
function x-yank() {
  local start=$CURSOR
  CUTBUFFER=$(__paste_from_clipboard) || return 1
  [[ -n $CUTBUFFER ]] || return 0
  zle .yank
  local end=$CURSOR
  (( end > start )) || return 0
  # Refresh FSH syntax highlight (if loaded)
  (( $+functions[_zsh_highlight] )) && _zsh_highlight
  # Apply the uniform "paste" highlight over the inserted range
  (( $+functions[_zsh_highlight_apply_zle_highlight] )) && \
    _zsh_highlight_apply_zle_highlight paste standout $start $end
  zle -R
}
function x-kill-line() {
  zle kill-line
  __copy_to_clipboard "$CUTBUFFER"
}
function x-kill-whole-line() {
  zle kill-whole-line
  __copy_to_clipboard "$CUTBUFFER"
}
function x-kill-buffer() {
  zle kill-buffer
  __copy_to_clipboard "$CUTBUFFER"
}
function x-backward-kill-word() {
  zle backward-kill-word
  __copy_to_clipboard "$CUTBUFFER"
}
function x-kill-word() {
  zle kill-word
  __copy_to_clipboard "$CUTBUFFER"
}
function x-backward-kill-word() {
  zle backward-kill-word
  __copy_to_clipboard "$CUTBUFFER"
}
zle -N x-kill-region
zle -N x-copy-region-as-kill
zle -N x-yank
zle -N x-kill-line
zle -N x-kill-whole-line
zle -N x-kill-buffer
zle -N x-backward-kill-word
zle -N x-kill-word
zle -N x-backward-kill-word

# Enable url-quote-magic: it replaces self-insert while editing the command line.
# When you type a URL and you hit a character that the shell would normally treat
# specially (?, &, #, ;, *, (, ), {}, |, <, >, etc), it auto-inserts a backslash
# in front of it only if the current “word” looks like it has a URI scheme
# (e.g. http://, https://, ftp://, file://) and the word isn’t already quoted.
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

function bracketed-paste-fast-filter() {
  local PASTED
  zle .bracketed-paste PASTED || return
  if (( ${+NUMERIC} )); then
    case $NUMERIC in
      (0) PASTED=${(q)PASTED}   ;; # shell-escape as one word (usually backslashes; no surrounding quotes)
      (1) PASTED=${(qq)PASTED}  ;; # single-quoted string, including the surrounding quotes
      (2) [[ $PASTED[1,2] == '~/' ]] && PASTED="${HOME}${PASTED[2,-1]}"
          PASTED=${(qqq)PASTED} ;; # double-quoted string (escape the chars that are special inside "")
    esac
  fi
  integer paste_start=$CURSOR
  LBUFFER+=$PASTED
  zle -f yank
  # Run first so _ZSH_HIGHLIGHT_PRIOR_BUFFER is updated — FSH's deferred
  # call will then see no buffer change and skip the region_highlight reset
  (( ${+functions[_zsh_highlight]} )) && _zsh_highlight
  # Now safely append paste styling on top
  (( ${+functions[_zsh_highlight_apply_zle_highlight]} )) && \
    _zsh_highlight_apply_zle_highlight paste standout "$paste_start" "$CURSOR"
}
zle -N bracketed-paste bracketed-paste-fast-filter

# Main utility of bracketed-paste (https://en.wikipedia.org/wiki/Bracketed-paste) is safety
# It makes pasted text get inserted as literal text into the ZLE buffer, instead of being
# "replayed" as a stream of keystrokes that can trigger editor widgets/bindings mid-paste.
# 
# This is relevant for:
#
# - Newlines in the paste: a naive paste can effectively "press Enter" and run partial
#   commands as it arrives; bracketed paste keeps it as inserted text for the editor to
#   accept as one paste (it still inserts newlines into the buffer, but zsh treats it as
#   paste content rather than interactive typing).
# - Control sequences / key bindings embedded in the paste (or timing issues): without
#   bracketed paste, pasting could accidentally invoke widgets bound to those sequences.
bindkey -M emacs $'\e[200~' bracketed-paste # binding for bracketed paste
printf '\033[?2004h'   # enable bracketed paste mode in the terminal

# Disable ZLE correction
# We prefer zstyle ':completion:*' completer _complete _approximate
unsetopt correct correctall

# Rebind keys to use the custom widget
bindkey "^w" x-kill-region
bindkey "^[w" x-copy-region-as-kill
bindkey '^Y' x-yank
bindkey -r "^[W"
bindkey -r "^[y"

bindkey "^K" x-kill-line
bindkey "^U" x-kill-whole-line
bindkey "^X^K" x-kill-buffer
bindkey "^[^H" x-backward-kill-word
bindkey "^[D" x-kill-word
bindkey "^[^?" backward-kill-word

# Edit the current command line in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

# Copy last word; useful for rename magick
bindkey "^[m" copy-prev-shell-word
