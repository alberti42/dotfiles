#!/bin/sh
# Claude Code status line — mirrors Powerlevel10k lean prompt style
# Left side: user@host  cwd  git-branch
# Right side: model  context%

input=$(cat)

# -- user@host (p10k context segment, dimmed) --
user=$(whoami)
host=$(hostname -s)

# -- current working directory (p10k dir segment, color 31 = cyan-blue) --
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
# Collapse $HOME to ~
home="$HOME"
cwd_display="${cwd/#$home/~}"

# -- git branch (p10k vcs segment) --
git_branch=""
if command -v git >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    git_branch=" $branch"
  fi
fi

# -- model (right side) --
model=$(echo "$input" | jq -r '.model.display_name // .model.id // ""')

# -- context window usage --
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_display=""
if [ -n "$used_pct" ]; then
  ctx_display=$(printf "  ctx:%.0f%%" "$used_pct")
fi

# -- assemble --
# Colors: 31=cyan-blue (dir), 33=yellow (git), 90=dark gray (user@host/separators), 0=reset
printf '\033[90m%s@%s\033[0m  \033[1;36m%s\033[0m\033[33m%s\033[0m  \033[90m%s\033[0m%s' \
  "$user" "$host" \
  "$cwd_display" \
  "$git_branch" \
  "$model" \
  "$ctx_display"
