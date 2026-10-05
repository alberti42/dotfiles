#!/usr/bin/env zsh
# Deploy private dotfiles to the public repo as ONE commit. Secrets are already
# redacted by the git clean filters (.gitattributes) when committing to the private repo.

# Worktree strategy
# - The script never touches the working tree of the private repo: it deploys
#   $PRIVATE_REF (default: origin/main), not the files on disk.
# - It creates a temporary git worktree outside the repo, on a disposable work
#   branch ($WORK_BRANCH, default: public-sync) reset to the current public tip
#   ($PUBLIC_REMOTE/$PUBLIC_BRANCH).
# - In that worktree it "transplants" the private tree, drops the private-only
#   files, and creates exactly one commit. The pre-commit hook scans it.
# - It pushes that commit to the public remote branch (unless PUSH=0).
# - An EXIT trap removes the worktree, also when the script fails or is interrupted.
#
# DRY_RUN=1 does everything except the push: the commit is created (and scanned
# by the pre-commit hook) on the local $WORK_BRANCH only.

set -euo pipefail

#=============================#
#          Config             #
#=============================#
PRIVATE_REMOTE="origin"          # dotfiles-private.git
PUBLIC_REMOTE="public-origin"    # dotfiles.git (your remote name)
PRIVATE_BRANCH="main"
PUBLIC_BRANCH="public"
WORK_BRANCH="public-sync"        # also named in git-hooks/pre-commit
COMMIT_PREFIX="Replace public with private tree"
DRY_RUN="${DRY_RUN:-0}"          # set to 1 to stop before the push
PUSH="${PUSH:-1}"                # set to 0 to skip pushing to the public remote
PRIVATE_REF="${PRIVATE_REF:-$PRIVATE_REMOTE/$PRIVATE_BRANCH}"  # override to deploy from local ref, e.g. PRIVATE_REF=main
[[ "$DRY_RUN" == "1" ]] && PUSH=0

DOTFILES=""                      # repo root (detected from this script)
TMPROOT=""                       # temporary directory holding the worktree
WORKTREE=""                      # the worktree itself

# Files that must NEVER be published
PRIVATE_ONLY_FILES=(
  "Sublime Text/Packages/User/sftp_servers/mqva-exp-control-dev.json"
)

#=============================#
#         Utilities           #
#=============================#
log() { print -r -- "[$(date +%H:%M:%S)] $*"; }
die() { print -r -- "ERROR: $*" >&2; exit 1; }

# Runs on every exit (success, error, Ctrl-C): remove the worktree and its
# registration. `git worktree remove` is not used because it refuses worktrees
# with submodules; deleting the directory and pruning has the same effect.
cleanup() {
  [[ -n "$TMPROOT" ]] || return 0
  builtin cd "$DOTFILES" 2>/dev/null || builtin cd /
  rm -rf -- "$TMPROOT"
  TMPROOT=""
  git -C "$DOTFILES" worktree prune
  log "Removed the temporary worktree."
}

#=============================#
#           Steps             #
#=============================#
require_repo_root() {
  DOTFILES="$(git -C "${0:A:h}" rev-parse --show-toplevel 2>/dev/null)" \
    || die "Not in a git repo (expected this script to live inside one)."
  builtin cd "$DOTFILES"
}

require_git_config() {
  # .git-dotfiles.conf defines the clean filters and enables git-hooks/pre-commit;
  # .git/config is not versioned, so each clone must include it once.
  [[ "$(git config --get dotfiles.included)" == "true" ]] \
    || die ".git-dotfiles.conf is not included. Run: git config include.path ../.git-dotfiles.conf"
}

fetch_remotes() {
  log "Fetching $PRIVATE_REMOTE/$PRIVATE_BRANCH and $PUBLIC_REMOTE/$PUBLIC_BRANCH…"
  git fetch "$PRIVATE_REMOTE" "$PRIVATE_BRANCH" --quiet
  git fetch "$PUBLIC_REMOTE" "$PUBLIC_BRANCH" --quiet
}

require_private_ref_in_sync() {
  # Fail-closed: if you have local commits not on $PRIVATE_REMOTE/$PRIVATE_BRANCH,
  # abort to avoid accidentally deploying an older tree.
  if git show-ref --verify --quiet "refs/heads/$PRIVATE_BRANCH" \
     && [[ "$PRIVATE_REF" == "$PRIVATE_REMOTE/$PRIVATE_BRANCH" ]] \
     && [[ "$(git rev-parse "$PRIVATE_BRANCH")" != "$(git rev-parse "$PRIVATE_REF")" ]]; then
    die "Local $PRIVATE_BRANCH differs from $PRIVATE_REF. Push your private branch first, or run with PRIVATE_REF=$PRIVATE_BRANCH to deploy local commits."
  fi
}

create_worktree() {
  # Remove a worktree on $WORK_BRANCH left by an earlier run (e.g. killed with
  # SIGKILL, which no trap can catch), then clear its registration.
  local stale
  stale="$(git worktree list --porcelain | awk -v b="branch refs/heads/$WORK_BRANCH" \
    '/^worktree /{p=substr($0,10)} $0==b{print p}')"
  if [[ -n "$stale" && "$stale" == */deploy_public.*/tree ]]; then
    log "Removing the worktree left by an earlier run: $stale"
    rm -rf -- "${stale:h}"
  fi
  git worktree prune
  TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/deploy_public.XXXXXX")"
  WORKTREE="$TMPROOT/tree"
  log "Creating worktree on $WORK_BRANCH at $PUBLIC_REMOTE/$PUBLIC_BRANCH…"
  git worktree add --quiet -B "$WORK_BRANCH" "$WORKTREE" "$PUBLIC_REMOTE/$PUBLIC_BRANCH"
  builtin cd "$WORKTREE"
}

transplant_private_tree() {
  # Index and files become exactly the tree of $PRIVATE_REF; paths it does not
  # contain are removed. Submodules stay as gitlinks and are not checked out.
  log "Transplanting tree from $PRIVATE_REF…"
  git restore --source "$PRIVATE_REF" --worktree --staged :/
}

drop_private_files() {
  # Fail-closed: if a file moved, was renamed or is no longer tracked, abort.
  local f
  for f in "${PRIVATE_ONLY_FILES[@]}"; do
    git ls-files --error-unmatch -- "$f" >/dev/null 2>&1 \
      || die "Expected private-only file is not tracked (rename/typo?): $f"
    git rm --quiet -f -- "$f"
    log "Dropped private-only file: $f"
  done
}

commit_and_push() {
  local private_tip
  private_tip="$(git rev-parse --short "$PRIVATE_REF")"

  if git diff --cached --quiet; then
    log "No changes to commit (public branch already matches $PRIVATE_REF)."
    return 0
  fi

  log "Diff summary:"
  git --no-pager diff --staged --stat

  log "Creating single commit…"
  git commit --quiet -m "$COMMIT_PREFIX (from $private_tip)"

  if [[ "$PUSH" == "1" ]]; then
    log "Pushing to $PUBLIC_REMOTE/$PUBLIC_BRANCH…"
    git push -u "$PUBLIC_REMOTE" "HEAD:$PUBLIC_BRANCH"
    log "✅ Deployed to $PUBLIC_REMOTE/$PUBLIC_BRANCH as a single commit."
  else
    log "Skipping push (DRY_RUN=$DRY_RUN, PUSH=$PUSH). The commit is on the local $WORK_BRANCH."
  fi
}

#=============================#
#            Main             #
#=============================#
# The traps are set here, at the top level: in zsh an EXIT trap set inside a
# function runs when that function returns.
# The ZERR and signal traps call cleanup themselves: zsh runs no EXIT trap when
# `set -e` ends the script inside a function, or when a trap calls `exit`.
trap cleanup EXIT
trap 'rc=$?; cleanup; exit $rc' ZERR
trap 'cleanup; exit 130' INT TERM HUP

require_repo_root
require_git_config
fetch_remotes
require_private_ref_in_sync
create_worktree
transplant_private_tree
drop_private_files
commit_and_push
