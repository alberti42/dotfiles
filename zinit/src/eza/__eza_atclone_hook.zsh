# Andrea Alberti, 2024

function __eza_atclone_hook() {
  # Find latest release
  local gh_repo="eza-community" &&
  local plugin=eza &&
  local tag_version site &&
  local releases="github.com/$gh_repo/$plugin/releases" &&
  tag_version=$({.zinit-download-file-stdout $releases/latest || .zinit-download-file-stdout $releases/latest 1;} 2>/dev/null | command grep -i -m 1 -o "href=./"$gh_repo"/"$plugin"/releases/tag/[^\"]\+") &&
  tag_version=${tag_version##*/} &&
  command mkdir -p "target/man" &&
  command git fetch --depth=1 origin tag "$tag_version" &&
  command git -c advice.detachedHead=false checkout "$tag_version" &&
  cargo build --release --locked &&
  local version=$(awk 'BEGIN { FS = "\"" } ; /^version/ { print $2 ; exit }' Cargo.toml) &&
  command wget -qO- https://github.com/eza-community/eza/releases/download/${tag_version}/man-${tag_version:1}.tar.gz | tar -xzf - &&
  command cp -vf target/man-${tag_version:1}/*.1 $ZINIT[MAN_DIR]/man1 &&
  command cp -vf target/man-${tag_version:1}/*.5 $ZINIT[MAN_DIR]/man5
}
_safe_one_off_load __eza_atclone_hook
