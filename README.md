# Dotfiles

These are my personal dotfiles, which include configurations for zsh shell, various tools and applications I use daily. They are designed to be lightweight and fast, supporting my workflow on macOS and Linux.

## Features
- **Zsh with Zinit**: My shell environment is based on `zsh`, managed with [`zinit`](https://github.com/zdharma-continuum/zinit) for plugin loading and configuration.
- **Sublime Text & Sublime Merge**: Custom settings and keybindings for a streamlined development experience.
- **iTerm2 Configuration**: Includes a custom color scheme and dynamic profile settings.
- **VS Code Settings**: Keybindings and settings for a consistent coding experience.
- **tmux Integration**: Custom scripts and settings for `tmux` to enhance terminal multiplexing.
- **Karabiner Customization**: Key remappings for efficiency using `karabiner.json`.
- **LaunchAgents**: Automations for launching background tasks, such as automatic BibDesk saving and tmux session management.
- **Custom Scripts**: Various utility scripts for workflow automation.

## Installation
To install these dotfiles, clone the repository and symlink the relevant files into your home directory:

```sh
# Clone the repository
git clone https://github.com/alberti42/dotfiles.git ~/dotfiles

# Symlink the required files (example for zshrc)
ln -s ~/dotfiles/zsh/.zshrc ~/.zshrc
```

## License
This repository is released under the MIT [License](LICENSE).

---

Feel free to explore, modify, and adapt these dotfiles to your needs!
