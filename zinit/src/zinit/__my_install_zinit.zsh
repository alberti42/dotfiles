#!/hint/zsh

function __my_install_zinit() {
  # Message informing about the installation process
  print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"

  # Create the directory for Zinit and set appropriate permissions
  command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"

  # Clone the Zinit repository
  command git clone --depth=1 https://github.com/alberti42/zinit "$HOME/.local/share/zinit/zinit.git" && \
      print -P "%F{33} %F{34}Installation successful.%f%b" || \
      print -P "%F{160} The clone has failed.%f%b"
}
_safe_one_off_load __my_install_zinit
