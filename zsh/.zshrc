#!/bin/zsh

# .zshrc is for interactive shells. You set options for the interactive shell there with the setopt
# and unsetopt commands. You can also load shell modules, set your history options, change your
# prompt, set up zle and completion, et cetera. You also set any variables that are only used in the
# interactive shell (e.g. $LS_COLORS).

###########################
# zinit installation      #
###########################

__zcompile_if_needed "$DOTFILES_DIR/zinit/src/zinit/zinit.zsh"
builtin source "$DOTFILES_DIR/zinit/src/zinit/zinit.zsh"

###########################
# INSTANT PROMPT          #
###########################

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then  
  __zcompile_if_needed_and_source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k/p10k-instant-prompt-${(%):-%n}.zsh"
fi

###########################
# ZINIT ANNEXES           #
###########################

# Load a few important annexes (i.e. extensions) without Turbo.
# These are actually required for many zinit packages to be imported.
zinit light-mode lucid depth=1 for \
  @zdharma-continuum/zinit-annex-binary-symlink \
  @zdharma-continuum/zinit-annex-patch-dl \
  @zdharma-continuum/zinit-annex-bin-gem-node

# Load annex (i.e. extension) to import meta plugins (i.e. sets of plugins)
# https://github.com/zdharma-continuum/zinit-annex-meta-plugins
zinit lucid light-mode depth=1 for @zdharma-continuum/zinit-annex-meta-plugins

# Manage rust updates
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/rust/rust.zsh"

##########################
# OMZ libs and plugins   #
##########################

# Check https://github.com/ohmyzsh/ohmyzsh/tree/master/lib
zinit wait lucid light-mode depth=1 for \
    OMZL::clipboard.zsh \
    OMZL::compfix.zsh \
    OMZL::completion.zsh \
    OMZL::correction.zsh \
    OMZL::grep.zsh \
    OMZL::history.zsh \
    OMZL::spectrum.zsh    

# Plugin binding GNU coreutils to their default names
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/gnu-utils/gnu-utils.zsh"

#####################
# PLUGINS           #
#####################
# For examples and inspiratations: https://github.com/crivotz/dot_files/blob/master/linux/zinit/zshrc

# Load vivid utility with automatic fast, loading of color scheme
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/vivid/vivid.zsh"

# Load further scripts by sharkdp
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/sharkdp/sharkdp.zsh"

# Load fzy
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/fzy/fzy.zsh"

# (not needed) Wrapper snippet for alberti42/LS_COLORS_TRUE_COLORS
# source "$DOTFILES_DIR/zinit/src/LS_COLORS_TRUE_COLORS/LS_COLORS_TRUE_COLORS.zsh"

# (not needed) Wrapper snippet for zcolors - extend the color theme of LS_COLORS to the other GNU commands
# source "$DOTFILES_DIR/zinit/src/zcolors/zcolors.zsh"

# Load history substring search https://github.com/zsh-users/zsh-history-substring-search
zinit wait lucid depth=1 light-mode for @zsh-users/zsh-history-substring-search

# Wrapper snippet for zsh-users/zsh-autosuggestions
# __zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/zsh-autosuggestions.zsh"

# Wrapper snippet for zsh-users/zsh-completions
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/zsh-completions.zsh"

# Wrapper snippet for zdharma-continuum/history-search-multi-word
# Disabled for now; replaced by fzf key bindings
# __zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/history-search-multi-word.zsh"

# Install jq: a lightweight command-line JSON processor akin to sed,awk,grep for JSON data (https://github.com/jqlang/jq)
zinit from"gh-r" lbin'jq-* -> jq' null lucid wait light-mode for @jqlang/jq

# Load powerlevel10k and customize prompt with ~/.p10k.zsh.
() {
  local XDG_CACHE_HOME=${XDG_CACHE_HOME:-~/.cache}/p10k # Covenient fix to change the cache folder to ~/.cache/p10k
  zinit depth=1 lucid light-mode for @romkatv/powerlevel10k
  [[ -f $DOTFILES_DIR/.p10k.zsh ]] && __zcompile_if_needed_and_source $DOTFILES_DIR/.p10k.zsh
}

# Wrapper function to load pyenv plugin
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/pyenv/pyenv.zsh"

# Conda completions
# zinit depth=1 light-mode lucid nocompile as'completion' from'gh' \
#   compile'_*' wait for @conda-incubator/conda-zsh-completion

# Import local plugins
{
  # Define the absolute path to your local plugin
  local __local_plugin_path="$DOTFILES_DIR/oh-my-zsh/custom/plugins"
  local __local_plugins=(
    # Import plugin ssh-tmux
    $__local_plugin_path/ssh-tmux

    # Import useful zsh completions
    blockf completions $__local_plugin_path/zsh-misc-completions

    # Import useful misc zsh functions
    atload:"wrap_restore_cursor nvim yazi tmux; restore_cursor" $__local_plugin_path/zsh-misc-functions
  )
  zinit lucid wait nocompile link light-mode for "${__local_plugins[@]}"
}

# Wrapper snippet for astral-sh/uv
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/uv/uv.zsh"

# Wrapper for command-line fuzzy finder fzf
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/fzf/fzf.zsh"

# Wrapper snippet for fzf-tab
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/fzf-tab/fzf-tab.zsh"

# Wrapper snippet for yazi
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/yazi/yazi.zsh"

# Wrapper snippet for Tmux
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/tmux/tmux.zsh"

# Import Tmux Plugins
() {
  local __tmux_plugins=(
    # @tmux-plugins/tmux-sensible
    # @tmux-plugins/tmux-cpu
    # @tmux-plugins/tmux-battery
    # id-as'tmux-plugins/tmux-tokyo-night' @janoamaral/tokyo-night-tmux
    # id-as'tmux-plugins/tmux-catppuccin' @catppuccin/tmux \
    @tmux-plugins/tmux-yank
    id-as'tmux-plugins/tmux-resurrect' @alberti42/fork-tmux-resurrect
    id-as'tmux-plugins/tmux-suspend' @MunifTanjim/tmux-suspend
    # id-as'tmux-plugins/tmux-menus' @jaclu/tmux-menus
    depth='' id-as'tmux-plugins/tmux-fzf-links' @alberti42/tmux-fzf-links
  )
  zinit lucid wait depth=1 as'null' from'gh' nocompile'!' for "${__tmux_plugins[@]}" 
}

# Import tig
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/tig/tig.zsh"

# Import plugin to synchronize tmux window with ssh sessions 
zinit depth=1 lucid wait light-mode for @alberti42/tmux-ssh-syncing

# Import 7z
zinit binary lucid wait light-mode depth=1 from'gh-r' lbin'7zz -> 7zz' for @ip7z/7zip  

# Import just command launcher
zinit binary lucid wait light-mode depth=1 from'gh-r' cp"just.1 -> $ZINIT[MAN_DIR]/man1" lbin'just -> just' for @casey/just

# Import eza
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/eza/eza.zsh"

# Import ripgrep
zinit binary lucid light-mode wait from'gh-r' lbin'**/rg(.exe|) -> rg' cp"ripgrep*/doc/rg.1 -> $ZINIT[MAN_DIR]/man1/rg.1" for @BurntSushi/ripgrep

# Import btop
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/btop/btop.zsh"

# Import viu
zinit binary lucid light-mode wait depth=1 from'gh-r' lbin'viu* -> viu' for @atanunq/viu

# Import neovim
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/neovim/neovim.zsh"

# Import imgcat
zinit binary lucid light-mode wait depth=1 from'gh-r' lbin'imgcat -> imgcat' for @danielgatis/imgcat 

# Import superfile
zinit binary lucid light-mode wait depth=1 from'gh-r' lbin'dist/superfile*/spf -> spf' for @yorukot/superfile

# Wrapper snippet for Sublime Text
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/sublime/sublime.zsh"

# Load syntax highlighting
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/fast-syntax-highlighting/fast-syntax-highlighting.zsh"

# Finalize Zsh initialization after all plugins and completions are loaded
zinit ice id-as'zinit/compinit' lucid as'null' wait atload'
  # Set compinit options to avoid re-generating .zcompdump if it exists and is up-to-date
  ZINIT[COMPINIT_OPTS]=-C
  
  # Initialize the Zsh completion system
  zicompinit

  # Replay any `compdef` calls that plugins made before `compinit` was ready
  zicdreplay
'
zinit light zdharma-continuum/null

#####################
# Keybindings       #
#####################

zinit is-snippet lucid light-mode nocompile link id-as'local/key-bindings' for $DOTFILES_DIR/zinit/src/key-bindings.zsh

#####################
# HISTORY           #
#####################
[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=$HISTSIZE
HISTDUP=erase

# https://www.zsh.org/mla/users/2014/msg00715.html
# zshaddhistory() { whence ${${(z)1}[1]} >| /dev/null || return 1 }

#####################
# SETOPT            #
#####################
# man zshoptions
setopt APPEND_HISTORY               # append history list to the history file rather than replacing it
setopt SHARE_HISTORY                # share history across all zsh sessions at the same time
# setopt EXTENDED_HISTORY           # record timestamp of command in HISTFILE
# setopt HIST_IGNORE_DUPS           # Do not enter command lines into the history list if they are duplicates
setopt HIST_IGNORE_ALL_DUPS         # If a new command line being added to the history list duplicates an older one, the older command is removed from the list
setopt HIST_SAVE_NO_DUPS            # When writing out the history file, older commands that duplicate newer ones are omitted
setopt HIST_IGNORE_SPACE            # Remove command lines from the history list when the first character on the line or of the expanded alias is a space
setopt HIST_FIND_NO_DUPS            # When searching for history entries in the line editor, do not display duplicates of a line previously found
# setopt HIST_EXPIRE_DUPS_FIRST     # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt HIST_VERIFY                  # don't execute the line directly; instead, perform history expansion 
setopt INC_APPEND_HISTORY           # add commands to HISTFILE in order of execution
setopt HASH_LIST_ALL                # hash everything before completion; makes the first completion slower but avoids false reports of spelling errors
setopt COMPLETE_ALIASES             # complete alisases
setopt ALWAYS_TO_END                # when completing from the middle of a word, move the cursor to the end of the word
setopt COMPLETE_IN_WORD             # allow completion from within a word/phrase
# setopt CORRECT                    # spelling correction for commands
setopt LIST_AMBIGUOUS               # complete as much of a completion until it gets ambiguous
setopt LIST_TYPES                   # when listing files that are possible completions, show the type of each file with a trailing identifying mark
setopt LIST_PACKED                  # try to make the completion list occupy less lines
setopt AUTO_MENU                    # automatically use menu completion after the second consecutive request for completion
setopt IGNORE_EOF                   # prevent Ctrl-D from exiting the shell; 10 consecutive CTRL-D events cause log out
setopt COMPLETE_ALIASES             # prevents aliases on the command line from being internally substituted before completion is attempted
setopt INTERACTIVE_COMMENTS         # allow comments even in interactive shells
# setopt GLOB_DOTS                  # do not require a leading `.' in a filename to be matched explicitly
# setopt PUSHD_SILENT               # do not print the directory stack after pushd or popd

# Changing/making/removing directory
# After: after https://github.com/ohmyzsh/ohmyzsh/blob/f733dc340b2a1c5b2e61a4da7de790b2f557175f/lib/directories.zsh
setopt AUTO_CD                     # Navigate directories without needing "cd" command.
setopt AUTO_PUSHD                  # Make cd push the old directory onto the directory stack.
setopt PUSHD_IGNORE_DUPS           # Don't push multiple copies of the same directory onto the directory stack.
setopt PUSHD_MINUS                 # Exchanges the meanings of `+' and `-' when used with a number to specify a directory in the stack.

#####################
# ENV VARIABLE      #
#####################

# macOS dependent variables
if [[ $OSTYPE =~ 'darwin*' ]]; then
  # Set CLICOLOR for Ansi Colors: With this setting,
  # BSD systems directly assume color output (e.g., -G option in ls)
  export CLICOLOR=1;

  if [[ ${SHELL:t} != zsh_macos_(arm|intel)_launcher ]]; then
    echo $ZINIT[col-warn]Warning:$ZINIT[col-rst] macOS shell set to $SHELL instead of zsh special launcher
  fi
fi

# Preferred editor for local and remote sessions
local editor_app

if [[ -n $SSH_CONNECTION ]]; then
  editor_app="rsubl"  # Remote Sublime Text
else
  # editor_app="emacsclient -a= -nw -c"  # Local emacs
  editor_app="subl"
fi

# Check whether the editor is found in the path
if command -v "$editor_app" >/dev/null 2>&1; then
  export EDITOR="$editor_app"
else
  # echo "Warning: '$editor_app' not found in the path. Using 'nano' as a fallback."
  export EDITOR="nano"
fi

# Always tell bat to use less -R for colors
# export BAT_PAGER="less -sR -j5"

# Man pager with modern look
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS: man uses backspace overstrikes, so we need col -bx
  export MANPAGER="sh -c 'col -bx | bat -l man --style=plain --paging=always'"
else
  # Linux: man already uses ANSI escapes, so skip col
  export MANPAGER="sh -c 'bat -l man --style=plain --paging=always'"
fi

# Configure PAGER to display 5 lines before search results (https://stackoverflow.com/a/14964428/4216175),
# to support the mouse, and support ANSI escape codes for colors (-R)
export LESS="-sR -j5 --mouse"

# Configure pager that is used by bat, git, and other utilities
export PAGER="less"

#####################
# ALIASES           #
#####################

# alias l="exa -abghHlS --git --group-directories-first"
alias ipInternal=ip-internal
alias ipExternal=ip-external
# alias ls='ls -G'
# alias ll='ls -l'
# alias lsd='ls -haltr'
# alias gls='gls --color=auto'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

alias -- -='cd -'
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

alias e='emacsclient -a= -nw -c'

alias diff='diff --color=auto'

# List directory contents
# alias ls='ls --color=auto'
# alias lsa='ls -lah'
# alias l='ls -lah'
# alias ll='ls -lh'
# alias la='ls -lAh'

# Shell
alias dotfiles="cd $DOTFILES_DIR"

# Docker
# alias dk="docker-compose"
# alias dkpurge="docker stop $(docker ps -aq) && docker rm $(docker ps -aq) && docker rmi $(docker images -q)"

# Configuration files
alias zshrc="$editor_app $HOME/.zshrc"
alias zshenv="$editor_app $HOME/.zshenv"
alias sshconf="$editor_app ~/.ssh/config"
alias tmuxconf="$editor_app $HOME/.config/tmux/tmux.conf"
alias weztermconf="$editor_app $HOME/.config/wezterm/wezterm.lua"
alias nvimconf="nvim $HOME/.config/nvim/init.lua"

# Misc
alias rsync='rsync -e "ssh -o RemoteCommand=None -o RequestTTY=no"'
alias zip='zip --symlinks --exclude "**/.DS_Store"'
alias rga='rg --no-ignore -aL.'
alias fda='fd -HI'
# alias mc='mc --nosubshell'

##########################
# Local customizations   #
##########################
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/rc_local.zsh"

# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
