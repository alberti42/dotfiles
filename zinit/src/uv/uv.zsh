# https://github.com/astral-sh/uv

zinit ice binary wait'0a' lucid from'gh-r' \
    lbin'!uv -> uv; uvx -> uvx' \
    depth=1 \
    lucid \
    atclone"*/uv generate-shell-completion zsh > _uv" \
    completion \
    atpull'%atclone'

zinit light @astral-sh/uv

zinit ice binary wait'0a' lucid from'gh-r' \
    lbin'!ruff -> ruff' \
    depth=1 \
    lucid \
    atclone"*/ruff generate-shell-completion zsh > _ruff" \
    completion \
    atpull'%atclone'

zinit light @astral-sh/ruff
