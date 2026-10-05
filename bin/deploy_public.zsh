#!/usr/bin/env zsh
# Deploy private dotfiles to the public repo as ONE commit. Secrets are already
# redacted by the git clean filters (.gitattributes) when committing to the private repo.

# Branch strategy
# - The script never commits on the private branch (e.g. main).
# - It creates/resets a disposable work branch ($WORK_BRANCH, default: public-sync)
#   at the current public tip ($PUBLIC_REMOTE/$PUBLIC_BRANCH).
# - It then "transplants" the private tree onto that work branch, drops the
#   private-only files, and creates exactly one commit.
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
PUBLIC_REMOTE="public-origin"     # dotfiles.git (your remote name)
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

require_git_config() {
  # .git-dotfiles.conf defines the clean filters and enables git-hooks/pre-commit;
  # .git/config is not versioned, so each clone must include it once.
  [[ "$(git config --get dotfiles.included)" == "true" ]] \
    || die ".git-dotfiles.conf is not included. Run: git config include.path ../.git-dotfiles.conf"
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
  if [[ "$DRY_RUN" == "1" ]]; then
    print -r -- "+ git switch -C '$WORK_BRANCH' '$PUBLIC_REMOTE/$PUBLIC_BRANCH'"
    return 0
  fi

  # Capture stdout+stderr in the if-condition so set -e doesn't fire on failure.
  local switch_out
  if switch_out="$(git switch -C "$WORK_BRANCH" "$PUBLIC_REMOTE/$PUBLIC_BRANCH" 2>&1)"; then
    return 0
  fi

  # git refuses to overwrite files that are untracked in the current branch but
  # tracked in the target (e.g. gitignored files, submodule content). Since
  # require_clean_tree already confirmed the working tree is clean, these are
  # safe to remove.
  local conflicts
  conflicts="$(awk '/would be overwritten/{found=1;next} /Please move/{found=0} found{gsub(/^[[:space:]]+/,"");print}' \
    <<< "$switch_out")"

  [[ -n "$conflicts" ]] || die "git switch failed for an unexpected reason:\n$switch_out"

  log "Removing conflicting untracked files before switch…"
  local f
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    log "  removing: $f"
    rm -rf -- "$f"
  done <<< "$conflicts"

  git switch -C "$WORK_BRANCH" "$PUBLIC_REMOTE/$PUBLIC_BRANCH" \
    || die "git switch failed even after removing conflicting files."
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

assert_file_exists() {
  local f="$1"
  [[ -f "$f" ]] || die "Missing required file: $f"
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

drop_private_files() {
  # Files that must NEVER be published
  local -a PRIVATE_ONLY_FILES=(
    "Sublime Text/Packages/User/sftp_servers/mqva-exp-control-dev.json"
  )

  drop_from_public "${PRIVATE_ONLY_FILES[@]}"
}

commit_and_push() {
  local private_tip
  private_tip="$(git rev-parse --short "$PRIVATE_REF")"

  log "Staging remaining changes…"
  run "git add -A"

  if git diff --cached --quiet; then
    log "No changes to commit (public branch already matches $PRIVATE_REF)."
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
    log "✅ Deployed to $PUBLIC_REMOTE/$PUBLIC_BRANCH as a single commit."
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
  require_git_config
  require_clean_tree
  fetch_remotes
  require_private_ref_in_sync
  switch_to_public_tip
  transplant_private_tree
  clean_submodules_hard
  drop_private_files
  commit_and_push
}

main "$@"
