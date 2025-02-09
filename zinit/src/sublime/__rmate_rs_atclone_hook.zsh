#!/hint/zsh

function __rmate_rs_atclone_hook() {
  # Deply subl shim to zinit directory
  cp -fv "${${(%):-%x}:h}/subl" .
  cp -fv "${${(%):-%x}:h}/rsubl" .
}
_safe_one_off_load __rmate_rs_atclone_hook
