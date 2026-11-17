#!/usr/bin/env -S zsh -f

# (c) Andrea Alberti, 2026

# links.zsh

# Create and check the symlinks from $HOME into this repo, and the copies of repo
# files outside $HOME, as listed in links.conf.
# Usage:
#   links.zsh install [-n]   create the links, and with sudo the copies that are missing
#                            or differ, for this OS (-n: print the actions only)
#   links.zsh check          report links in $HOME that point into the repo but are not
#                            in links.conf, entries whose link is missing or wrong, and
#                            copies that are missing or differ from the repo file

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

# Hardware model identifier, the same string on both OSes (e.g. iMacPro1,1).
MODEL=
case $OS in
  macos) MODEL=$(sysctl -n hw.model 2>/dev/null) ;;
  linux) [[ -r /sys/class/dmi/id/product_name ]] && MODEL=$(</sys/class/dmi/id/product_name) ;;
esac

trim() { local s=${1##[[:space:]]##}; print -r -- "${s%%[[:space:]]##}" }

# Whether an <os> field applies to this machine: "<os>" or "<os>[<model pattern>]".
# <os> is all, macos or linux; the pattern is a zsh glob matched against $MODEL,
# with | between alternatives. Dies at line $n of links.conf on a malformed field.
applies() {
  local field=$1 base pattern='*'
  if [[ $field == (#b)([^\[]##)\[([^\]]##)\] ]]; then
    base=$match[1] pattern=$match[2]
  else
    base=$field
  fi
  [[ $base == (all|macos|linux) ]] ||
    die "$CONF:$n: unknown OS '$field' (all, macos, linux, optionally followed by [<model pattern>])"
  [[ $base == all || $base == $OS ]] && [[ $MODEL == (${~pattern}) ]]
}

#--- parse links.conf ------------------------------------------------------
typeset -a LINKS IGNORES      # LINKS: link paths for this OS, in file order
typeset -A TARGETS KNOWN      # TARGETS[link]: targets joined by " | "; KNOWN: links of any OS
typeset -a COPIES             # COPIES: absolute destination paths for this OS, in file order
typeset -A SOURCES            # SOURCES[dest]: source path, relative to the repo

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
    copy)
      cos=${rest%%[[:space:]]*}
      rest=$(trim "${rest#$cos}")
      [[ $rest == *' <- '* ]] || die "$CONF:$n: expected 'copy <os> <dest> <- <source>'"
      dest=$(trim "${rest%% <- *}")
      [[ $dest == /* ]] || die "$CONF:$n: copy destination must be absolute: $dest"
      if applies "$cos"; then
        COPIES+=("$dest")
        SOURCES[$dest]=$(trim "${rest#* <- }")
      fi ;;
    all|macos|linux|all\[*\]|macos\[*\]|linux\[*\])
      [[ $rest == *' -> '* ]] || die "$CONF:$n: expected '<link> -> <target>'"
      link=$(trim "${rest%% -> *}")
      [[ $link != /* ]] || die "$CONF:$n: link must be relative to \$HOME: $link"
      KNOWN[$link]=1
      if applies "$os"; then
        LINKS+=("$link")
        TARGETS[$link]=$(trim "${rest#* -> }")
      fi ;;
    *)
      die "$CONF:$n: unknown kind '$os' (all, macos, linux, optionally with [<model pattern>], ignore, copy)" ;;
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

# True if $HOME/<link> is not itself a symlink but sits under a parent directory
# that resolves into the repo (e.g. an old-style ~/.config/yazi -> repo link).
# Such a path IS a repo file: moving it aside and linking it would replace the
# repo file with a symlink to itself.
via_parent_link() {
  local dst=$HOME/$1 parent
  [[ -L $dst ]] && return 1
  parent=${dst:h:A}
  [[ $parent == $REPO || $parent == $REPO/* ]]
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
    if via_parent_link "$link"; then
      warn "skipped $link: a parent directory of ~/$link is a symlink into the repo;" \
           "replace that parent link with a real directory, then rerun"
      (( ++skipped )); continue
    fi
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

  # Copies outside $HOME, installed with sudo when missing or different
  local dest
  integer copied=0 current=0 failed=0
  for dest in "${COPIES[@]}"; do
    src=$REPO/${SOURCES[$dest]}
    if [[ ! -f $src ]]; then
      warn "skipped $dest: ${SOURCES[$dest]} does not exist in the repo"
      (( ++failed )); continue
    fi
    if [[ -r $dest ]] && cmp -s "$src" "$dest"; then (( ++current )); continue; fi
    log "copying: ${SOURCES[$dest]} -> $dest"
    if act sudo install -D -m 644 "$src" "$dest"; then
      (( ++copied ))
    else
      warn "failed to copy ${SOURCES[$dest]} to $dest"
      (( ++failed ))
    fi
  done
  (( $#COPIES )) && log "copied $copied, already current $current, failed $failed"

  (( skipped == 0 && failed == 0 ))
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
    if via_parent_link "$link"; then
      log "parent link:  $link (a parent directory is a symlink into the repo)"
    elif [[ -L $dst ]]; then
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

  # Copies that are missing or differ from the repo file
  local dest src
  for dest in "${COPIES[@]}"; do
    src=$REPO/${SOURCES[$dest]}
    if [[ ! -f $src ]]; then
      log "no source:    $dest <- ${SOURCES[$dest]}"
    elif [[ ! -e $dest ]]; then
      log "missing:      $dest"
    elif [[ ! -r $dest ]]; then
      log "unreadable:   $dest"
    elif ! cmp -s "$src" "$dest"; then
      log "differs:      $dest <- ${SOURCES[$dest]}"
    else
      continue
    fi
    (( ++issues ))
  done

  if (( $#unlisted )); then
    log "# not listed in links.conf (set the OS column before pasting):"
    print -rl -- "${unlisted[@]}"
  fi

  (( issues == 0 )) && log "all links and copies match $CONF"
  (( issues == 0 ))
}

case ${1-} in
  install) shift; install_links "$@" ;;
  check)   check_links ;;
  *)       print -r -u2 "usage: ${0:t} install [-n] | check"; exit 2 ;;
esac
