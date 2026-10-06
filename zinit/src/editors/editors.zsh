# https://github.com/alberti42/fork-rmate-rs

# For keybinding, add the ICE: src'key-bindings.zsh'
zinit ice light-mode \
  binary \
  atclone"source '${${(%):-%x}:a:h}/__rmate_rs_atclone_hook.zsh'" \
  dl'
    https://raw.githubusercontent.com/alberti42/zsh-misc-completions/refs/heads/main/src/_subl;
    https://raw.githubusercontent.com/alberti42/zsh-misc-completions/refs/heads/main/src/_remacs;
    https://raw.githubusercontent.com/alberti42/zsh-misc-completions/refs/heads/main/src/_rmate;
  ' \
  atpull'%atclone' \
  from'gh' \
  lucid \
  nocompile \
  blockf \
  ver"merged" \
  lbin'rmate -> rmate; rsubl -> rsubl; remacs -> remacs'
zinit light @alberti42/fork-rmate-rs
