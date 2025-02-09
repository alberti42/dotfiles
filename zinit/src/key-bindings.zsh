#!/hint/zsh

# man zshzle; note: the key bindings are case sensitive!
# for other key bindings check: https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/refs/heads/master/lib/key-bindings.zsh

# Load fuzzy search for history and bind to arrow keys
autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search  # Up arrow
bindkey "^[OA" up-line-or-beginning-search  # Up arrow
autoload -U down-line-or-beginning-search
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
if [[ -n "${terminfo[ht]}" ]]; then
  bindkey "${terminfo[ht]}" expand-or-complete  # Tab key via terminfo
else
  bindkey "^i" expand-or-complete              # Default fallback for Tab
fi
# [Shift-Tab] - move through the completion menu backwards
if [[ -n "${terminfo[kcbt]}" ]]; then
  bindkey "${terminfo[kcbt]}" reverse-menu-complete
else
  bindkey "^[[Z" reverse-menu-complete    # Fallback for Shift-Tab
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
__copy_to_clipboard() {
  if command -v pbcopy &>/dev/null; then
    # macOS
    print -rn -- "$1" | pbcopy
  elif command -v xclip &>/dev/null; then
    # linux
    print -rn -- "$1" xclip -selection clipboard
  fi
}
__paste_from_clipboard() {
  if command -v pbpaste &>/dev/null; then
    # macOS
    pbpaste
  elif command -v xclip &>/dev/null; then
    # linux
    xclip -selection clipboard -o
  fi
}
x-kill-region() {
  zle kill-region
  __copy_to_clipboard "$CUTBUFFER"
}
x-copy-region-as-kill() {
  zle copy-region-as-kill
  __copy_to_clipboard "$CUTBUFFER"
}
x-yank () {
  CUTBUFFER=$(__paste_from_clipboard)
  zle yank
}
x-kill-line() {
  zle kill-line
  __copy_to_clipboard "$CUTBUFFER"
}
x-kill-whole-line() {
  zle kill-whole-line
  __copy_to_clipboard "$CUTBUFFER"
}
x-kill-buffer() {
  zle kill-buffer
  __copy_to_clipboard "$CUTBUFFER"
}
x-backward-kill-word() {
  zle backward-kill-word
  __copy_to_clipboard "$CUTBUFFER"
}
x-kill-word() {
  zle kill-word
  __copy_to_clipboard "$CUTBUFFER"
}
x-backward-kill-word() {
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
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

# Copy last word; useful for rename magick
bindkey "^[m" copy-prev-shell-word
