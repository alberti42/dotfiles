#!/usr/bin/env zsh
# Deploy private dotfiles to the public repo as ONE commit, with secrets sanitized.
# Works on macOS (BSD sed) and Linux (GNU sed).

set -euo pipefail

#=============================#
#          Config             #
#=============================#
PRIVATE_REMOTE="origin"          # dotfiles-private.git
PUBLIC_REMOTE="pubic-origin"     # dotfiles.git (your remote name)
PRIVATE_BRANCH="main"
PUBLIC_BRANCH="public"
WORK_BRANCH="public-sync"
COMMIT_PREFIX="Replace public with private tree"
DRY_RUN="${DRY_RUN:-0}"          # set to 1 to print actions without changing anything

#=============================#
#         Utilities           #
#=============================#
log() { print -r -- "[$(date +%H:%M:%S)] $*"; }
die() { print -r -- "ERROR: $*" >&2; exit 1; }

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    print -r -- "+ $*"
  else
    eval "$*"
  fi
}

require_repo_root() {
  git rev-parse --show-toplevel >/dev/null 2>&1 || die "Not in a git repo."
}

require_clean_tree() {
  git diff --quiet || die "Working tree has unstaged changes."
  git diff --cached --quiet || die "Index has staged changes."
}

fetch_remotes() {
  log "Fetching $PRIVATE_REMOTE/$PRIVATE_BRANCH and $PUBLIC_REMOTE/$PUBLIC_BRANCH…"
  run "git fetch '$PRIVATE_REMOTE' '$PRIVATE_BRANCH' --quiet"
  run "git fetch '$PUBLIC_REMOTE'  '$PUBLIC_BRANCH' --quiet"
}

switch_to_public_tip() {
  log "Switching to $WORK_BRANCH at $PUBLIC_REMOTE/$PUBLIC_BRANCH…"
  run "git switch -C '$WORK_BRANCH' '$PUBLIC_REMOTE/$PUBLIC_BRANCH'"
}

# Reset every submodule to the exact commit recorded by the superproject
clean_submodules_hard() {
  log "Cleaning submodules to recorded commits…"
  # Sync URLs from .gitmodules (in case they changed)
  run "git submodule sync --recursive"
  # Force-checkout recorded SHAs (discard local edits in submodules)
  run "git submodule update --init --recursive --checkout --force"
  # Extra belt-and-suspenders: scrub untracked files in submodules
  run "git submodule foreach --recursive 'git reset --hard && git clean -fdx || true'"
}

transplant_private_tree() {
  log "Transplanting tree from $PRIVATE_REMOTE/$PRIVATE_BRANCH…"
  run "git restore --source '$PRIVATE_REMOTE/$PRIVATE_BRANCH' --worktree --staged :/"
}

# Cross-platform sed -i -E (requires GNU sed)
sedi() {
  local re="$1"; shift
  local sedcmd=""

  # Prefer GNU sed explicitly if available
  if command -v gsed >/dev/null 2>&1; then
    sedcmd="gsed"
  elif command -v sed >/dev/null 2>&1 && sed --version >/dev/null 2>&1; then
    sedcmd="sed"
  else
    echo "❌ ERROR: GNU sed (gsed) not found. Please install it (e.g. 'brew install gnu-sed')." >&2
    echo "    BSD sed is unsafe for secret redaction — aborting." >&2
    exit 1
  fi

  # Now run GNU sed safely
  "$sedcmd" -i -E "$re" "$@"
}

safe_edit_and_stage() {
  local pattern="$1"; shift
  local f
  for f in "$@"; do
    if [[ -f "$f" ]]; then
      log "Sanitizing: $f"
      if [[ "$DRY_RUN" == "1" ]]; then
        print -r -- "+ sed -E '$pattern' -- $f"
      else
        sedi "$pattern" "$f"
        git add -- "$f"
      fi
    else
      log "Skipping missing file: $f"
    fi
  done
}

#=============================#
#       Sanitization          #
#=============================#
sanitize_sublime_sftp() {
  # 1) Sublime Text/Packages/User/SFTP.sublime-settings
  safe_edit_and_stage \
    's/("product_key"\s*:\s*")[^"]*(")/\1...\2/g' \
    "Sublime Text/Packages/User/SFTP.sublime-settings"
}

sanitize_vscode_settings() {
  # 2) Library/Application Support/Code/settings.json
  safe_edit_and_stage \
    's/("ltex\.languageToolOrg\.username"\s*:\s*")[^"]*(")/\1...\2/g' \
    "Library/Application Support/Code/settings.json"
  safe_edit_and_stage \
    's/("ltex\.languageToolOrg\.apiKey"\s*:\s*")[^"]*(")/\1...\2/g' \
    "Library/Application Support/Code/settings.json"
}

sanitize_sublime_ltex() {
  # 3) Sublime Text/Packages/User/LSP-ltex-ls.sublime-settings
  safe_edit_and_stage \
    's/("ltex\.languageToolOrg\.username"\s*:\s*")[^"]*(")/\1...\2/g' \
    "Sublime Text/Packages/User/LSP-ltex-ls.sublime-settings"
  safe_edit_and_stage \
    's/("ltex\.ltex-ls\.languageToolOrgApiKey"\s*:\s*")[^"]*(")/\1...\2/g' \
    "Sublime Text/Packages/User/LSP-ltex-ls.sublime-settings"
}

drop_from_public() {
  # Remove paths from the **index only**, keep working tree intact,
  # and ensure they’re ignored going forward.
  local file_to_be_dropped
  for file_to_be_dropped in "$@"; do
    run "git rm -f -- \"$file_to_be_dropped\" || true"
  done
}

sanitize_all() {
  log "Starting sanitization…"
  sanitize_sublime_sftp
  sanitize_vscode_settings
  sanitize_sublime_ltex

   # Files that must NEVER be published
  local -a PRIVATE_ONLY_FILES=(
    "Sublime Text/Packages/User/sftp_servers/mqva-exp-control-dev.json"
  )

  # Drop the private files 
  drop_from_public "${PRIVATE_ONLY_FILES[@]}"

  # Optional: best-effort scan for other obvious secrets (does not block).
  # if command -v rg >/dev/null 2>&1; then
  #  log "Scanning for likely secrets (best-effort)…"
  #  run "rg -n --hidden --iglob '!*\.git/*' '(password|passwd|api[_-]?key|secret|token|ssh-)' || true"
  # fi
}

commit_and_push() {
  local private_tip
  private_tip="$(git rev-parse --short "$PRIVATE_REMOTE/$PRIVATE_BRANCH")"

  log "Staging remaining changes…"
  run "git add -A"

  log "Diff summary:"
  run "git -P diff --staged --stat || true"

  log "Creating single commit…"
  run "git commit -m '$COMMIT_PREFIX (from $private_tip), secrets sanitized'"

  log "Pushing to $PUBLIC_REMOTE/$PUBLIC_BRANCH…"
  run "git push -u '$PUBLIC_REMOTE' 'HEAD:$PUBLIC_BRANCH'"

  log "✅ Deployed to $PUBLIC_REMOTE/$PUBLIC_BRANCH as a single sanitized commit."
}

#=============================#
#            Main            #
#=============================#
main() {
  require_repo_root
  require_clean_tree
  fetch_remotes
  switch_to_public_tip
  transplant_private_tree
  clean_submodules_hard
  sanitize_all
  commit_and_push
}

main "$@"
