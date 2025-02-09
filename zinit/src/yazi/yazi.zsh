# https://github.com/sxyazi/yazi

# provides the ability to change the current working directory when exiting Yazi
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# ya pack -a yazi-rs/plugins:max-preview

zinit binary lucid wait light-mode depth=1 from'gh-r' \
  lbin'yazi-*/ya -> ya; yazi-*/yazi -> yazi' \
  for @sxyazi/yazi
