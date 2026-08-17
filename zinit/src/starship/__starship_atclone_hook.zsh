# Andrea Alberti, 2026

function __starship_atclone_hook() {
  # Generate the zsh init script ONCE at install/update time — instead of
  # running `starship init zsh` on every shell startup — and pre-compile it to
  # wordcode so atload only has to source the .zwc.
  local init_file="${STARSHIP_INIT_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/starship/init.zsh}"
  command mkdir -p "${init_file:h}"

  # Use the freshly extracted binary in the plugin dir (cwd during atclone),
  # not relying on it being on PATH yet.
  ./starship init zsh >| "$init_file"

  # Compile with the same flags as the dotfiles' __zcompile_if_needed helpers.
  zcompile -Uz -- "$init_file" "${init_file}.zwc"
}
_safe_one_off_load __starship_atclone_hook
