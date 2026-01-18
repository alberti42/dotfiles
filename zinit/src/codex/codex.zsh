# https://developers.openai.com/codex/cli/

# Codex CLI (installed/updated via npm when you run `zinit update`)
zinit ice \
  id-as"openai/codex" \
  lucid \
  run-atpull \
  atpull'%atclone' \
  atclone'npm i -g @openai/codex@latest && codex completion zsh > _codex' \
  completions \
  nocompile
zinit load zdharma-continuum/null
