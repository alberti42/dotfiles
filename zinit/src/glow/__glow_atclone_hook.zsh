# Andrea Alberti, 2024

function __glow_atclone_hook() {
  mv glow_*/* . &&
  rm -r glow_* &&
  gunzip manpages/glow.1.gz &&
  cp manpages/glow.1 $ZINIT[MAN_DIR]/man1/ &&
  mv completions/glow.zsh _glow
}
_safe_one_off_load __glow_atclone_hook
