# Andrea Alberti, 2024

function __tmux_atclone_hook() {
  # Find latest release
  local gh_repo=tmux &&
  local plugin=tmux &&
  local tag_version site &&
  local releases="github.com/$gh_repo/$plugin/releases" &&
  tag_version=$({.zinit-download-file-stdout $releases/latest || .zinit-download-file-stdout $releases/latest 1;} 2>/dev/null | command grep -i -m 1 -o "href=./"$gh_repo"/"$plugin"/releases/tag/[^\"]\+") &&
  tag_version=${tag_version##*/} &&
  command git fetch --depth=1 origin tag "$tag_version"
  command git -c advice.detachedHead=false checkout "$tag_version" &&
  sh autogen.sh &&
  ./configure --enable-utf8proc &&
  make &&
  mkdir -p $ZPFX/{bin,man/man1} &&
  cp -vf tmux.1 $ZPFX/man/man1
}
_safe_one_off_load __tmux_atclone_hook
