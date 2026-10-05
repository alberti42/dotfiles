#!/usr/bin/env zsh

# (c) Andrea Alberti, 2026

# sed_require.zsh

# Git clean filter: applies sed -E expressions to stdin and fails if any expression
# makes no substitution (e.g. the key it should redact was renamed).
# Usage, in a git config filter (git passes the path as %f):
#   clean = bin/sed_require.zsh %f '<expr1>' ['<expr2>' ...]
#   required = true

file=$1; shift
(( $# )) || { print -r -u2 "sed_require: no sed expression given for $file"; exit 2 }

tmp=$(mktemp) || exit 1
trap 'rm -f "$tmp"' EXIT
cat > "$tmp"

args=()
for expr in "$@"; do
  # Ask sed whether $expr made a substitution (even one that leaves the text unchanged):
  #   -e "$expr"    the expression, unchanged
  #   -e 't hit'    if it made a substitution on this line, jump to :hit
  #   -e 'b'        otherwise go to the next line (nothing printed, because of -n)
  #   -e ':hit'
  #   -e 's/^/x/p'  print a non-empty marker
  #   -e 'q'        stop at the first hit
  hit=$(sed -E -n -e "$expr" -e 't hit' -e 'b' -e ':hit' -e 's/^/x/p' -e 'q' "$tmp") || exit 1
  if [[ -z $hit ]]; then
    print -r -u2 "sed_require: no match in $file for: $expr"
    exit 1
  fi
  args+=(-e "$expr")
done

sed -E "${args[@]}" "$tmp"
