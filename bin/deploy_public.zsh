#!/usr/bin/env zsh
# Deploy private dotfiles to the public repo as ONE commit, with secrets sanitized.
# Works on macOS (BSD sed) and Linux (GNU sed).

# Branch strategy
# - The script never commits on the private branch (e.g. main).
# - It creates/resets a disposable work branch ($WORK_BRANCH, default: public-sync)
#   at the current public tip ($PUBLIC_REMOTE/$PUBLIC_BRANCH).
# - It then "transplants" the private tree onto that work branch, runs strict
#   sanitization, and creates exactly one commit.
# - Finally, it pushes that commit to the public remote branch (unless PUSH=0)
#   and checks out the private branch again.
#
# Why this juggling exists:
# - Starting from the public tip makes each run reproducible and safe.
# - Using a disposable work branch avoids detached HEAD and avoids mutating a
#   long-lived local public branch.
# - The work branch is safe to delete/recreate; it is just a staging area.

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
PUSH="${PUSH:-1}"                # set to 0 to skip pushing to the public remote
DOTFILES="${DOTFILES:-}"          # repo root (auto-detected from this script)
PRIVATE_REF="${PRIVATE_REF:-$PRIVATE_REMOTE/$PRIVATE_BRANCH}"  # override to deploy from local ref, e.g. PRIVATE_REF=main

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
  local script_dir repo_root
  script_dir="${0:A:h}"
  repo_root="$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null)" \
    || die "Not in a git repo (expected this script to live inside one)."

  DOTFILES="$repo_root"
  builtin cd "$DOTFILES" || die "Failed to cd to repo root: $DOTFILES"
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

require_private_ref_in_sync() {
  # Fail-closed: if you have local commits not on $PRIVATE_REMOTE/$PRIVATE_BRANCH,
  # abort to avoid accidentally deploying an older tree.
  local local_ref="refs/heads/$PRIVATE_BRANCH"
  if git show-ref --verify --quiet "$local_ref"; then
    local local_sha remote_sha
    local_sha="$(git rev-parse "$PRIVATE_BRANCH")"
    remote_sha="$(git rev-parse "$PRIVATE_REMOTE/$PRIVATE_BRANCH")"
    if [[ "$local_sha" != "$remote_sha" && "$PRIVATE_REF" == "$PRIVATE_REMOTE/$PRIVATE_BRANCH" ]]; then
      die "Local $PRIVATE_BRANCH differs from $PRIVATE_REMOTE/$PRIVATE_BRANCH. Push your private branch first, or run with PRIVATE_REF=$PRIVATE_BRANCH to deploy local commits."
    fi
  fi
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
  log "Transplanting tree from $PRIVATE_REF…"
  run "git restore --source '$PRIVATE_REF' --worktree --staged :/"
}

# Cross-platform sed -i -E (requires GNU sed)
gnu_sed_cmd() {
  # Prefer GNU sed explicitly if available.
  if command -v gsed >/dev/null 2>&1; then
    print -r -- "gsed"
    return 0
  fi

  if command -v sed >/dev/null 2>&1 && sed --version >/dev/null 2>&1; then
    print -r -- "sed"
    return 0
  fi

  die "GNU sed (gsed) not found. Install it (e.g. 'brew install gnu-sed'). BSD sed is unsafe for secret redaction."
}

sedi() {
  local expr="$1"; shift
  local sedcmd
  sedcmd="$(gnu_sed_cmd)"
  "$sedcmd" -i -E "$expr" "$@"
}

assert_file_exists() {
  local f="$1"
  [[ -f "$f" ]] || die "Missing required file: $f"
}

sed_has_match() {
  local re="$1" file="$2"
  local sedcmd
  sedcmd="$(gnu_sed_cmd)"

  # Escape / for the address regex.
  local addr_re="${re//\//\\/}"
  "$sedcmd" -nE "/$addr_re/{q 0}; \$q 1" "$file"
}

sed_render() {
  local expr="$1" file="$2"
  local sedcmd
  sedcmd="$(gnu_sed_cmd)"
  "$sedcmd" -E "$expr" "$file"
}

strict_redact_and_stage() {
  local f="$1"; shift
  local pre_re="$1"; shift
  local sed_expr="$1"; shift
  local post_re="$1"; shift

  assert_file_exists "$f"

  if ! sed_has_match "$pre_re" "$f"; then
    die "Expected secret pattern not found in $f (pattern drift or file changed)."
  fi

  log "Sanitizing (strict): $f"
  if [[ "$DRY_RUN" == "1" ]]; then
    print -r -- "+ sed -E '$sed_expr' -- $f"
  fi

  local tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/deploy_public.XXXXXX")"

  if [[ "$DRY_RUN" == "1" ]]; then
    sed_render "$sed_expr" "$f" >"$tmp"

    if command cmp -s -- "$f" "$tmp"; then
      command rm -f -- "$tmp"
      die "Sanitization made no changes in $f (already sanitized or pattern drift). Aborting."
    fi

    if ! sed_has_match "$post_re" "$tmp"; then
      command rm -f -- "$tmp"
      die "Sanitization did not produce expected redacted output in $f. Aborting."
    fi

    command rm -f -- "$tmp"
    return 0
  fi

  # Non-dry-run: edit in-place to preserve file mode bits.
  command cp -f -- "$f" "$tmp"
  sedi "$sed_expr" "$f"

  if command cmp -s -- "$f" "$tmp"; then
    command rm -f -- "$tmp"
    die "Sanitization made no changes in $f (already sanitized or pattern drift). Aborting."
  fi
  command rm -f -- "$tmp"

  if ! sed_has_match "$post_re" "$f"; then
    die "Sanitization did not produce expected redacted output in $f. Aborting."
  fi

  git add -- "$f"
}

#=============================#
#       Sanitization          #
#=============================#
sanitize_sublime_sftp() {
  # 1) Sublime Text/Packages/User/SFTP.sublime-settings
  strict_redact_and_stage \
    "Sublime Text/Packages/User/SFTP.sublime-settings" \
    '("product_key"\s*:\s*")[^"]*(")' \
    's/("product_key"\s*:\s*")[^"]*(")/\1...\2/g' \
    '("product_key"\s*:\s*")\.\.\.(")'
}

sanitize_vscode_settings() {
  # 2) Library/Application Support/Code/settings.json
  strict_redact_and_stage \
    "Library/Application Support/Code/settings.json" \
    '("ltex\.languageToolOrg\.username"\s*:\s*")[^"]*(")' \
    's/("ltex\.languageToolOrg\.username"\s*:\s*")[^"]*(")/\1...\2/g' \
    '("ltex\.languageToolOrg\.username"\s*:\s*")\.\.\.(")'
  strict_redact_and_stage \
    "Library/Application Support/Code/settings.json" \
    '("ltex\.languageToolOrg\.apiKey"\s*:\s*")[^"]*(")' \
    's/("ltex\.languageToolOrg\.apiKey"\s*:\s*")[^"]*(")/\1...\2/g' \
    '("ltex\.languageToolOrg\.apiKey"\s*:\s*")\.\.\.(")'
}

sanitize_sublime_ltex() {
  # 3) Sublime Text/Packages/User/LSP-ltex-ls.sublime-settings
  strict_redact_and_stage \
    "Sublime Text/Packages/User/LSP-ltex-ls.sublime-settings" \
    '("ltex\.languageToolOrg\.username"\s*:\s*")[^"]*(")' \
    's/("ltex\.languageToolOrg\.username"\s*:\s*")[^"]*(")/\1...\2/g' \
    '("ltex\.languageToolOrg\.username"\s*:\s*")\.\.\.(")'
  strict_redact_and_stage \
    "Sublime Text/Packages/User/LSP-ltex-ls.sublime-settings" \
    '("ltex\.ltex-ls\.languageToolOrgApiKey"\s*:\s*")[^"]*(")' \
    's/("ltex\.ltex-ls\.languageToolOrgApiKey"\s*:\s*")[^"]*(")/\1...\2/g' \
    '("ltex\.ltex-ls\.languageToolOrgApiKey"\s*:\s*")\.\.\.(")'
}

sanitize_launchd_env() {
  # 4) .local/bin/launchd-env.zsh
  strict_redact_and_stage \
    ".local/bin/launchd-env.zsh" \
    '^(export[[:space:]]+OPENCODE_SERVER_PASSWORD[[:space:]]*=[[:space:]]*)"[^"]*"' \
    's/^(export[[:space:]]+OPENCODE_SERVER_PASSWORD[[:space:]]*=[[:space:]]*)"[^"]*"/\1"..."/g' \
    '^(export[[:space:]]+OPENCODE_SERVER_PASSWORD[[:space:]]*=[[:space:]]*)"\.\.\."'
}

sanitize_opencode_knuspr() {
  # 5) .config/opencode/opencode.json
  # Hide knuspr MCP credentials.
  strict_redact_and_stage \
    ".config/opencode/opencode.json" \
    '("rhl-email"\s*:\s*")[^"]*(")' \
    's/("rhl-email"\s*:\s*")[^"]*(")/\1...\2/g' \
    '("rhl-email"\s*:\s*")\.\.\.(")'
  strict_redact_and_stage \
    ".config/opencode/opencode.json" \
    '("rhl-pass"\s*:\s*")[^"]*(")' \
    's/("rhl-pass"\s*:\s*")[^"]*(")/\1...\2/g' \
    '("rhl-pass"\s*:\s*")\.\.\.(")'
}

drop_from_public() {
  # Fail-closed: if the file moved/renamed/untracked, abort.
  local file_to_be_dropped
  for file_to_be_dropped in "$@"; do
    assert_file_exists "$file_to_be_dropped"

    if [[ "$DRY_RUN" == "1" ]]; then
      git ls-files --error-unmatch -- "$file_to_be_dropped" >/dev/null 2>&1 \
        || die "Expected private-only file is not tracked (rename/typo?): $file_to_be_dropped"
      print -r -- "+ git ls-files --error-unmatch -- '$file_to_be_dropped'"
      print -r -- "+ git rm -f -- '$file_to_be_dropped'"
      continue
    fi

    git ls-files --error-unmatch -- "$file_to_be_dropped" >/dev/null 2>&1 \
      || die "Expected private-only file is not tracked (rename/typo?): $file_to_be_dropped"
    git rm -f -- "$file_to_be_dropped"
  done
}

verify_sanitization() {
  log "Verifying sanitization…"

  # In dry-run we already validated each redaction via a temp render.
  if [[ "$DRY_RUN" == "1" ]]; then
    return 0
  fi

  # Verify redactions are present (fail if missing).
  assert_file_exists "Sublime Text/Packages/User/SFTP.sublime-settings"
  sed_has_match '("product_key"\s*:\s*")\.\.\.(")' \
    "Sublime Text/Packages/User/SFTP.sublime-settings" \
    || die "Redacted product_key not found in Sublime Text/Packages/User/SFTP.sublime-settings"

  assert_file_exists "Library/Application Support/Code/settings.json"
  sed_has_match '("ltex\.languageToolOrg\.username"\s*:\s*")\.\.\.(")' \
    "Library/Application Support/Code/settings.json" \
    || die "Redacted ltex.languageToolOrg.username not found in Library/Application Support/Code/settings.json"
  sed_has_match '("ltex\.languageToolOrg\.apiKey"\s*:\s*")\.\.\.(")' \
    "Library/Application Support/Code/settings.json" \
    || die "Redacted ltex.languageToolOrg.apiKey not found in Library/Application Support/Code/settings.json"

  assert_file_exists "Sublime Text/Packages/User/LSP-ltex-ls.sublime-settings"
  sed_has_match '("ltex\.languageToolOrg\.username"\s*:\s*")\.\.\.(")' \
    "Sublime Text/Packages/User/LSP-ltex-ls.sublime-settings" \
    || die "Redacted ltex.languageToolOrg.username not found in Sublime Text/Packages/User/LSP-ltex-ls.sublime-settings"
  sed_has_match '("ltex\.ltex-ls\.languageToolOrgApiKey"\s*:\s*")\.\.\.(")' \
    "Sublime Text/Packages/User/LSP-ltex-ls.sublime-settings" \
    || die "Redacted ltex.ltex-ls.languageToolOrgApiKey not found in Sublime Text/Packages/User/LSP-ltex-ls.sublime-settings"

  assert_file_exists ".local/bin/launchd-env.zsh"
  sed_has_match '^(export[[:space:]]+OPENCODE_SERVER_PASSWORD[[:space:]]*=[[:space:]]*)"\.\.\."' \
    ".local/bin/launchd-env.zsh" \
    || die "Redacted OPENCODE_SERVER_PASSWORD not found in .local/bin/launchd-env.zsh"

  assert_file_exists ".config/opencode/opencode.json"
  sed_has_match '("rhl-email"\s*:\s*")\.\.\.(")' \
    ".config/opencode/opencode.json" \
    || die "Redacted rhl-email not found in .config/opencode/opencode.json"
  sed_has_match '("rhl-pass"\s*:\s*")\.\.\.(")' \
    ".config/opencode/opencode.json" \
    || die "Redacted rhl-pass not found in .config/opencode/opencode.json"

  # Verify private-only paths are no longer tracked.
  if git ls-files --error-unmatch -- "Sublime Text/Packages/User/sftp_servers/mqva-exp-control-dev.json" >/dev/null 2>&1; then
    die "Private-only file is still tracked: Sublime Text/Packages/User/sftp_servers/mqva-exp-control-dev.json"
  fi
}

sanitize_all() {
  log "Starting sanitization…"
  sanitize_sublime_sftp
  sanitize_vscode_settings
  sanitize_sublime_ltex
  sanitize_launchd_env
  sanitize_opencode_knuspr

    # Files that must NEVER be published
  local -a PRIVATE_ONLY_FILES=(
    "Sublime Text/Packages/User/sftp_servers/mqva-exp-control-dev.json"
  )

  # Drop the private files 
  drop_from_public "${PRIVATE_ONLY_FILES[@]}"

  verify_sanitization

  # Optional: best-effort scan for other obvious secrets (does not block).
  # if command -v rg >/dev/null 2>&1; then
  #  log "Scanning for likely secrets (best-effort)…"
  #  run "rg -n --hidden --iglob '!*\.git/*' '(password|passwd|api[_-]?key|secret|token|ssh-)' || true"
  # fi
}

commit_and_push() {
  local private_tip
  private_tip="$(git rev-parse --short "$PRIVATE_REF")"

  log "Staging remaining changes…"
  run "git add -A"

  if git diff --cached --quiet; then
    log "No changes to commit (public branch already matches sanitized $PRIVATE_REF)."
    log "Checking out local $PRIVATE_BRANCH"
    run "git checkout '$PRIVATE_BRANCH'"
    return 0
  fi

  log "Diff summary:"
  run "git --no-pager diff --staged --stat || true"

  log "Creating single commit…"
  run "git commit -m '$COMMIT_PREFIX (from $private_tip)'"

  if [[ "$PUSH" == "1" ]]; then
    log "Pushing to $PUBLIC_REMOTE/$PUBLIC_BRANCH…"
    run "git push -u '$PUBLIC_REMOTE' 'HEAD:$PUBLIC_BRANCH'"
    log "✅ Deployed to $PUBLIC_REMOTE/$PUBLIC_BRANCH as a single sanitized commit."
  else
    log "Skipping push (PUSH=$PUSH). Review locally, then push when ready."
  fi
  
  log "Checking out local $PRIVATE_BRANCH"
  run "git checkout '$PRIVATE_BRANCH'"
}

#=============================#
#            Main            #
#=============================#
main() {
  require_repo_root
  require_clean_tree
  fetch_remotes
  require_private_ref_in_sync
  switch_to_public_tip
  transplant_private_tree
  clean_submodules_hard
  sanitize_all
  commit_and_push
}

main "$@"
