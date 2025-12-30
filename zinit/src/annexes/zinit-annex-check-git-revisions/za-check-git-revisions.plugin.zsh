# zdharma-continuum/zinit-annex-git-revisions
# git-revisions.zsh
#
# License: MIT License

# Executed at Zinit's startup
@zinit-register-annex "zinit-annex-git-revisions" \
    hook:e-\!atpull-pre \
    "zif-git-revisions-hook" \
    "zif-git-revisions-help" \
    "check-new-revisions"

# The hook that implements the ice
zif-git-revisions-hook() {
    # File
    if [[ "$1" = plugin ]]; then
        local type="$1" user="$2" plugin="$3" id_as="$4" dir="${5#%}" hook="$6"
    else
        local type="$1" url="$2" id_as="$3" dir="${4#%}" hook="$5"
    fi

    # The ice isn't active
    (( ${+ICE[check-new-revisions]} )) || return 0

    # There were new commits
    (( ZINIT[annex-multi-flag:pull-active] >= 2 )) && return 0

    # No new commits, so halt the annex chain
    return 1
}

# The help handler for the ice
zif-git-revisions-help() {
    print -r -- "
Zinit-annex-git-revisions annex
===============================

Ice-mods provided:
- check-new-revisions

This ice, when given before \`atpull'' or \`atclone'' ices, will cause them
to be executed only if the update has fetched new commits (i.e. if the Git
revisions differ). Without this ice, atpull'' is executed always.
"
}
