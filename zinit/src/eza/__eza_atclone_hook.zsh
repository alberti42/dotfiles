# Andrea Alberti, 2024

function __eza_atclone_hook() {
  # Find latest release
  local gh_repo="eza-community" &&
  local plugin=eza &&
  local tag_version site &&
  local releases="github.com/$gh_repo/$plugin/releases" &&
  tag_version=$({.zinit-download-file-stdout $releases/latest || .zinit-download-file-stdout $releases/latest 1;} 2>/dev/null | command grep -i -m 1 -o "href=./"$gh_repo"/"$plugin"/releases/tag/[^\"]\+") &&
  tag_version=${tag_version##*/} &&
  command git fetch --depth=1 origin tag "$tag_version" &&
  command git -c advice.detachedHead=false checkout "$tag_version" &&
  cargo build --release --locked &&
  mkdir -p "target/man" &&
  local version=$(awk 'BEGIN { FS = "\"" } ; /^version/ { print $2 ; exit }' Cargo.toml) &&
  for page in eza.1 eza_colors.5 eza_colors-explanation.5; do
    # requires pandoc to be installed
    sed "s/\$version/v${version}/g" "man/${page}.md" | pandoc --standalone -f markdown -t man > "${CARGO_TARGET_DIR:-target}/man/${page}"; \
  done &&
  cp -vf target/man/*.1 $ZINIT[MAN_DIR]/man1 &&
  cp -vf target/man/*.5 $ZINIT[MAN_DIR]/man5
}
_safe_one_off_load __eza_atclone_hook
