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

# Initialize and update all submodules
cd ~/dotfiles
git submodule update --init --recursive

# Symlink the required files (example for zshrc)
ln -s ~/dotfiles/zsh/.zshrc ~/.zshrc
```

## Submodules

This repository includes the following submodules:

**Zsh plugins**
- [`oh-my-zsh/custom/plugins/zsh-misc-completions`](https://github.com/alberti42/zsh-misc-completions)
- [`oh-my-zsh/custom/plugins/zsh-indent-control`](https://github.com/alberti42/zsh-indent-control)
- [`oh-my-zsh/custom/plugins/zsh-appearance-control`](https://github.com/alberti42/zsh-appearance-control)
- [`oh-my-zsh/custom/plugins/zsh-opencode-tab`](https://github.com/alberti42/zsh-opencode-tab)
- [`oh-my-zsh/custom/plugins/tmux-fzf-links`](https://github.com/alberti42/tmux-fzf-links)
- [`oh-my-zsh/custom/plugins/tmux-ssh-syncing`](https://github.com/alberti42/tmux-ssh-syncing)

**Emacs**
- [`.config/emacs`](https://github.com/alberti42/emacs-config)

**Yazi**
- [`.config/yazi/flavors`](https://github.com/yazi-rs/flavors)
- [`.config/yazi/plugins/fazif.yazi`](https://github.com/alberti42/fork-fazif.yazi)
- [`.config/yazi/plugins/fzf-plus.yazi`](https://github.com/alberti42/fzf-plus.yazi)
- [`.config/yazi/plugins/faster-piper.yazi`](https://github.com/alberti42/faster-piper.yazi)
- [`.config/yazi/plugins/bat.yazi`](https://github.com/mgumz/yazi-plugin-bat)
- [`.config/yazi/plugins/command.yazi`](https://github.com/KKV9/command.yazi)

**eza**
- [`.config/eza/eza-themes`](https://github.com/eza-community/eza-themes)

**Sublime Text**
- [`Sublime Text/Packages/Recent Files Tracker`](https://github.com/alberti42/sublime-recent-files-tracker)
- [`Sublime Text/Packages/VirtualenvSelector`](https://github.com/alberti42/sublime-virtualenv-selector)
- [`Sublime Text/Packages/Dictionaries`](https://github.com/titoBouzout/Dictionaries)

**Zinit**
- [`zinit/src/annexes/zinit-annex-latest-release`](https://github.com/alberti42/zinit-annex-latest-release)

**Other**
- [`.local/share/EXIF-Syntax`](https://github.com/alberti42/EXIF-Syntax)

## License
This repository is released under the MIT [License](LICENSE).

---

Feel free to explore, modify, and adapt these dotfiles to your needs!
