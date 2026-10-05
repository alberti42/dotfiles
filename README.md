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
Clone the repository with its submodules, then create the symlinks from `$HOME` into the repository with `bin/links.zsh`:

```sh
git clone https://github.com/alberti42/dotfiles.git ~/dotfiles
cd ~/dotfiles
git submodule update --init --recursive

bin/links.zsh install -n   # print the actions only
bin/links.zsh install
```

`install` first creates `~/.config/dotfiles` pointing at the clone, then creates the links for this OS through that path. Anything already at a link's path is moved to `<name>.bak-<timestamp>`.

The submodules must be downloaded before `install`: some files in the repository are symlinks into them.

### The list of links
[`links.conf`](links.conf) lists the links, one per line:

```
<os>  <link, relative to $HOME>  ->  <target, relative to the repo>
```

`<os>` is `all`, `macos` or `linux`. Alternative targets are separated by ` | `: `install` links the first, `check` accepts any (for links switched at runtime). An `ignore <path>` line makes `check` skip links at or under that path.

```sh
bin/links.zsh check
```

`check` reports entries whose link is missing or wrong, and prints the links in `$HOME` that point into the repository but are not in `links.conf`, in `links.conf` format, ready to paste.

### Systems where the login shell cannot be changed
Where `chsh` is not allowed, the linked `~/.bashrc` (`bash/.bashrc`) starts zsh for interactive top-level shells. Non-interactive shells (`scp`, `rsync`, `ssh host cmd`) and `bash` typed from another shell stay in bash.

### Committing from a clone
If you commit to this repository, include `.git-dotfiles.conf` in the clone's git configuration once. It defines the git clean filters that redact secrets:

```sh
git config include.path ../.git-dotfiles.conf
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
