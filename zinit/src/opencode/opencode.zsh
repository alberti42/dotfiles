# https://github.com/anomalyco/opencode

# Codex CLI (installed/updated via npm when you run `zinit update`)
zinit ice \
  id-as"zen/opencode" \
  lucid \
  run-atpull \
  atpull'%atclone' \
  atclone'npm i -g opencode-ai@latest && opencode completion > _opencode' \
  completions \
  nocompile
zinit load zdharma-continuum/null
