# https://github.com/ltex-plus/ltex-ls-plus

zinit ice wait'0' lucid from'gh-r' light-mode extract'!' \
  atclone"source '${${(%):-%x}:a:h}/__lsp-ltex-plus_atclone_hook.zsh'" \
  atpull'%atclone'
zinit light @ltex-plus/ltex-ls-plus

# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
