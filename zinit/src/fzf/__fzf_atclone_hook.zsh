function __fzf_atclone_hook() {
  # Find latest release
  local gh_repo=junegunn &&
  local plugin=fzf &&
  local tag_version site &&
  local releases="github.com/$gh_repo/$plugin/releases" &&
  tag_version=$({.zinit-download-file-stdout $releases/latest || .zinit-download-file-stdout $releases/latest 1;} 2>/dev/null | command grep -i -m 1 -o "href=./"$gh_repo"/"$plugin"/releases/tag/[^\"]\+") &&
  tag_version=${tag_version##*/} &&
  command git fetch --depth=1 origin tag "$tag_version" &&
  command git -c advice.detachedHead=false checkout "$tag_version" &&
  PREFIX=$ZPFX make bin/fzf &&
  bin/fzf --zsh >! shell/init.zsh &&
  cp -vf bin/fzf(|-tmux) $ZPFX/bin/ &&
  cp -vf bin/fzf-preview.sh $ZPFX/bin/fzf-preview &&
  cp -vf man/man1/fzf(|-tmux).1 $ZPFX/man/man1/
}
_safe_one_off_load __fzf_atclone_hook
