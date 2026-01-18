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
