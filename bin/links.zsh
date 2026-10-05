#!/usr/bin/env -S zsh -f

# (c) Andrea Alberti, 2026

# links.zsh

# Create and check the symlinks from $HOME into this repo, as listed in links.conf.
# Usage:
#   links.zsh install [-n]   create the links for this OS (-n: print the actions only)
#   links.zsh check          report links in $HOME that point into the repo but are not
#                            in links.conf, and entries whose link is missing or wrong

setopt extended_glob no_unset pipe_fail

REPO=${0:A:h:h}                     # real path of the repo
CONF=$REPO/links.conf
DOTFILES=$HOME/.config/dotfiles     # links point through this path, like $DOTFILES_DIR
SCAN_DEPTH=8                        # how deep `check` looks for links under $HOME

log()  { print -r -- "$*" }
warn() { print -r -u2 -- "links: $*" }
die()  { warn "$*"; exit 1 }

case $OSTYPE in
  darwin*) OS=macos ;;
  linux*)  OS=linux ;;
  *)       die "unsupported OS: $OSTYPE" ;;
esac

trim() { local s=${1##[[:space:]]##}; print -r -- "${s%%[[:space:]]##}" }

#--- parse links.conf ------------------------------------------------------
typeset -a LINKS IGNORES      # LINKS: link paths for this OS, in file order
typeset -A TARGETS KNOWN      # TARGETS[link]: targets joined by " | "; KNOWN: links of any OS

[[ -r $CONF ]] || die "cannot read $CONF"
integer n=0
while IFS= read -r line; do
  (( ++n ))
  [[ $line == [[:space:]]#(\#*|) ]] && continue
  os=${line%%[[:space:]]*}
  rest=$(trim "${line#$os}")
  case $os in
    ignore)
      IGNORES+=("$rest") ;;
    all|macos|linux)
      [[ $rest == *' -> '* ]] || die "$CONF:$n: expected '<link> -> <target>'"
      link=$(trim "${rest%% -> *}")
      [[ $link != /* ]] || die "$CONF:$n: link must be relative to \$HOME: $link"
      KNOWN[$link]=1
      if [[ $os == all || $os == $OS ]]; then
        LINKS+=("$link")
        TARGETS[$link]=$(trim "${rest#* -> }")
      fi ;;
    *)
      die "$CONF:$n: unknown kind '$os' (all, macos, linux, ignore)" ;;
  esac
done < "$CONF"

# Targets of a link, one per array element.
targets_of() {
  local t; reply=()
  for t in "${(@s: | :)TARGETS[$1]}"; do reply+=("$(trim "$t")"); done
}

# True if $HOME/<link> is a symlink resolving to one of its targets.
link_ok() {
  local dst=$HOME/$1 t
  [[ -L $dst ]] || return 1
  targets_of "$1"
  for t in "${reply[@]}"; do
    [[ ${dst:A} == ${${:-$REPO/$t}:A} ]] && return 0
  done
  return 1
}

#--- install ---------------------------------------------------------------
install_links() {
  local dry=0
  [[ ${1-} == -n ]] && dry=1

  act() { if (( dry )); then print -r -- "+ ${(q-)@}"; else "$@"; fi }

  # ~/.config/dotfiles -> this repo, the path every link goes through
  if [[ ! -e $DOTFILES && ! -L $DOTFILES ]]; then
    act mkdir -p "${DOTFILES:h}"
    act ln -s "$REPO" "$DOTFILES"
  elif [[ ${DOTFILES:A} != $REPO ]]; then
    die "$DOTFILES exists but does not resolve to $REPO"
  fi

  local link dst src backup stamp=$(date +%Y%m%d-%H%M%S)
  integer made=0 kept=0 skipped=0
  for link in "${LINKS[@]}"; do
    if link_ok "$link"; then (( ++kept )); continue; fi
    targets_of "$link"
    if [[ ! -e $REPO/${reply[1]} ]]; then
      warn "skipped $link: ${reply[1]} does not exist in the repo"
      (( ++skipped )); continue
    fi
    dst=$HOME/$link
    src=$DOTFILES/${reply[1]}
    if [[ -e $dst || -L $dst ]]; then
      backup=$dst.bak-$stamp
      log "moving aside: $link -> ${backup#$HOME/}"
      act mv "$dst" "$backup"
    fi
    act mkdir -p "${dst:h}"
    act ln -s "$src" "$dst"
    (( ++made ))
  done
  log "created $made, already correct $kept, skipped $skipped"
  (( skipped == 0 ))
}

#--- check -----------------------------------------------------------------
check_links() {
  integer issues=0
  local link dst l rel t i
  local -a unlisted

  # Entries whose link is missing or wrong
  for link in "${LINKS[@]}"; do
    link_ok "$link" && continue
    dst=$HOME/$link
    if [[ -L $dst ]]; then
      log "wrong target: $link -> ${dst:A}"
    elif [[ -e $dst ]]; then
      log "not a link:   $link"
    else
      log "missing:      $link"
    fi
    (( ++issues ))
  done

  # Links into the repo that links.conf does not list
  local -a prune=(-name .git -o -name node_modules -o -path "$REPO")
  for i in "${IGNORES[@]}"; do prune+=(-o -path "$HOME/$i"); done

  find "$HOME" -maxdepth $SCAN_DEPTH \( "${prune[@]}" \) -prune -o -type l -print 2>/dev/null |
  while IFS= read -r l; do
    t=${l:A}
    [[ $t == $REPO || $t == $REPO/* ]] || continue
    rel=${l#$HOME/}
    [[ $rel == .config/dotfiles ]] && continue
    (( ${+KNOWN[$rel]} )) && continue
    for i in "${IGNORES[@]}"; do [[ $rel == $i || $rel == $i/* ]] && continue 2; done
    unlisted+=("all    $rel -> ${t#$REPO/}")
    (( ++issues ))
  done

  if (( $#unlisted )); then
    log "# not listed in links.conf (set the OS column before pasting):"
    print -rl -- "${unlisted[@]}"
  fi

  (( issues == 0 )) && log "all links match $CONF"
  (( issues == 0 ))
}

case ${1-} in
  install) shift; install_links "$@" ;;
  check)   check_links ;;
  *)       print -r -u2 "usage: ${0:t} install [-n] | check"; exit 2 ;;
esac
