# Andrea Alberti, 2024

function __eza_atclone_hook() {
  tag_version=$ICE[ver]
  command mkdir -p "target/man" &&
  cargo build --release --locked &&
  local version=$(command awk 'BEGIN { FS = "\"" } ; /^version/ { print $2 ; exit }' Cargo.toml) &&
  command wget -qO- https://github.com/eza-community/eza/releases/download/${tag_version}/man-${tag_version:1}.tar.gz | \
  command tar -xzf -
  command cp -vf target/man-${tag_version:1}/*.1 $ZINIT[MAN_DIR]/man1 &&
  command cp -vf target/man-${tag_version:1}/*.5 $ZINIT[MAN_DIR]/man5
}
_safe_one_off_load __eza_atclone_hook
