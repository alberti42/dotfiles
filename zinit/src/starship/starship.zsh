# https://github.com/starship/starship

# Keep starship's config alongside this snippet so it is version-controlled
# together with the wrapper (same self-contained style as the eza/glow snippets).
# `${(%):-%x}` expands to this file's path; `:a:h` is its absolute directory.
typeset -g _STARSHIP_CFG_FULL="${${(%):-%x}:a:h}/starship.toml"
typeset -g _STARSHIP_CFG_LITE="${${(%):-%x}:a:h}/starship-lite.toml"

# Per-directory config switch. Starship has no native per-directory config, so a
# chpwd hook re-points $STARSHIP_CONFIG. In "junk-drawer" dirs (full of random
# files) the lite config is used: its `format` omits every language module, so
# Starship never scans for their files nor forks `<lang> --version` — keeping the
# prompt instant no matter what got dropped there. Everywhere else: the full config.
# (/private/tmp is macOS's real path behind the /tmp symlink.)
typeset -ga _STARSHIP_LITE_DIRS=(
    "$HOME/Downloads"
    "$HOME/Desktop"
    /tmp
    /private/tmp
)
_starship_pick_config() {
    local d
    for d in $_STARSHIP_LITE_DIRS; do
        if [[ $PWD/ == $d/* ]]; then
            export STARSHIP_CONFIG="$_STARSHIP_CFG_LITE"
            return
        fi
    done
    export STARSHIP_CONFIG="$_STARSHIP_CFG_FULL"
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _starship_pick_config
_starship_pick_config   # set it for the directory the shell starts in

# Pre-generated, pre-compiled `starship init zsh` script. The atclone hook
# produces it once at install/update time and compiles it to wordcode; every
# shell startup then merely sources the .zwc instead of forking `starship init`.
typeset -g STARSHIP_INIT_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/starship/init.zsh"

# Install the starship binary from its GitHub releases. A prompt is loaded
# synchronously (NO `wait`/turbo) so it is ready on the very first line with no
# fallback-prompt flash — mirroring how powerlevel10k was loaded here.
#
# - atclone/atpull: (re)generate + compile the init script (both files always
#   written together, so the .zwc is never stale and init.zsh is never edited).
# - atload: just source it — zsh automatically loads the compiled .zwc when it
#   sources the .zsh path — then preserve the terminal setup that used to ride on
#   powerlevel10k's atload: disable XON/XOFF flow control (Ctrl-S/Ctrl-Q) and
#   unset the EOF/start/stop control characters.
#
# `$STARSHIP_INIT_FILE` is double-quoted here, so it is expanded at source time
# (the value is already set above) and baked into the ice string as a literal
# path — atload never depends on the variable being visible at its own runtime.
zinit ice \
    null \
    from'gh-r' \
    lbin'starship -> starship' \
    nocompile \
    lucid \
    light-mode \
    atclone"source '${${(%):-%x}:a:h}/__starship_atclone_hook.zsh'" \
    atpull"%atclone" \
    atload"source $STARSHIP_INIT_FILE; stty -ixon eof undef start undef stop undef"
zinit light @starship/starship
