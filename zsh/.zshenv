#!/bin/zsh

# .zshenv is always sourced. It often contains exported variables that should be available to other
# programs. For example, $PATH, $EDITOR, and $PAGER are often set in .zshenv. Also, you can set
# $ZDOTDIR in .zshenv to specify an alternative location for the rest of your zsh configuration.

#########################
# MISC CUSTOMIZATION    #
#########################

# Make the zsh $path array unique
declare -aU path

# Configure 1Password identity agent
if [ -d "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password" ]; then
  export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
fi

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Configure path
if [[ "/usr/local/bin" ]]; then
  path=("/usr/local/bin" $path)
fi
if [[ -d "$HOME/bin" ]]; then
  path=("$HOME/bin" $path)
fi
if [[ -d "$HOME/.local/bin" ]]; then
  path=("$HOME/.local/bin" $path)
fi

# Latex path
if [[ -d "/Library/TeX/texbin" ]]; then
  path=("/Library/TeX/texbin" $path)
fi

# Location of dotfiles
DOTFILES_DIR=$HOME/.config/dotfiles

# This can be useful to some POSIX applications
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share

# Ubuntu calls compinit in /etc/zshrc. To avoid the slowdown from this call and if the user loads any
# completion-equipped plugins, add the following lines to ~/.zshenv:
skip_global_compinit=1

#########################
# HOMEBREW SETUP        #
#########################

# Detect HomeBrew (macOS)
if [[ $OSTYPE =~ 'darwin*' ]]; then
  local brew_path="${$(command -v /opt/homebrew/bin/brew || command -v /usr/local/bin/brew):-}"
  if [[ -n "$brew_path" ]] then
    local homebrew_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/homebrew"
    local shellenv_script="${homebrew_cache_dir}/shellenv.zsh"
    if [[ ! -f "$shellenv_script" ]]; then
      mkdir -p "$homebrew_cache_dir"
      "$brew_path" shellenv > "$shellenv_script"
      zcompile -Uz -- "$shellenv_script"
    fi
    () {
      local PATH # Prevent overwriting PATH
      source "$shellenv_script"
    }
    path=("${brew_path:h}" $path)
  fi
fi

#########################
# PERL SETUP            #
#########################

if [[ -d "$HOME/perl5/bin" ]]; then
  path=("$HOME/perl5/bin" $path)
  PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
  PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
  PERL_MB_OPT="--install_base \"$HOME/perl5\""; export PERL_MB_OPT;
  PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"; export PERL_MM_OPT;
fi

#########################
# RUBY SETUP            #
#########################

if (( ${+HOMEBREW_PREFIX} )); then
  # Path to HomeBrew-version of Ruby
  if [ -d "$HOMEBREW_PREFIX/opt/ruby/bin" ]; then
    export path=("$HOMEBREW_PREFIX/opt/ruby/bin" $path)
    export path=("$(gem environment gemdir)/bin" $path)
  fi
fi

#########################
# JULIA SETUP           #
#########################

if [ -d "$HOME/.juliaup/bin" ]; then
  path+=("$HOME/.juliaup/bin")
fi

###########################
# RUST SETUP              #
###########################

export RUSTUP_HOME="$HOME/.rustup" CARGO_HOME="$HOME/.cargo"
if [ ! -d "$CARGO_HOME/bin" ]; then
  curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable
fi
path+=("$HOME/.cargo/bin")

###########################
# os default paths        #
###########################

if [[ $OSTYPE == darwin* ]]; then
  # Execution time ~ 3m
  # eval $(/usr/libexec/path_helper -s)

  local -a added_paths=( \
    /usr/local/bin \
    /usr/bin \
    /bin \
    /usr/sbin \
    /sbin \
  )  
  # append the dirs
  path+=(${^added_paths})
fi

###########################
# zinit installation      #
###########################

source "$DOTFILES_DIR/zinit/src/zinit/zinit.zsh"
