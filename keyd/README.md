# keyd: Emacs bindings in GNOME Text Editor

GNOME Text Editor is a GTK 4 app. GTK 4 has no key themes, so it ignores
`gsettings set org.gnome.desktop.interface gtk-key-theme 'Emacs'`, and its own
`keybindings` setting offers only `'default'` and `'vim'`.

[keyd](https://github.com/rvaiya/keyd) remaps keys below the toolkit, at the
evdev level:

| File | Installed as | Role |
|---|---|---|
| `default.conf` | `/etc/keyd/default.conf` (copied by `links.conf`) | keyd grabs every keyboard and passes all keys through unchanged |
| `app.conf` | `~/.config/keyd/app.conf` (linked by `links.conf`) | the Emacs bindings, for the window class `org-gnome-texteditor` |
| `../.local/share/gnome-shell/extensions/keyd@keyd.rvaiya.github.com` | linked by `links.conf` | GNOME extension that writes the class of the focused window to `$XDG_RUNTIME_DIR/keyd.fifo`, and starts `keyd-application-mapper -d` when enabled |

`keyd-application-mapper` reads the fifo and, at each focus change, runs
`keyd bind reset` followed by the bindings of the matching section of
`app.conf`.

The extension is `data/gnome-extension-45` from keyd v2.6.0, with `"50"` and
`"51"` added to `shell-version`. The COPR package
`gnome-shell-extension-keyd` requires `gnome-shell < 50`, so it is not
installed.

## Install

```sh
sudo dnf copr enable alternateved/keyd
sudo dnf install keyd
~/.config/dotfiles/bin/links.zsh install   # copies default.conf to /etc/keyd/
sudo systemctl enable --now keyd
sudo usermod -aG keyd $USER        # access to /var/run/keyd.socket, for `keyd bind`
```

Then log out and back in (for the group and for GNOME Shell to find the
extension), and run:

```sh
gnome-extensions enable keyd@keyd.rvaiya.github.com
```

`links.conf` lists `default.conf` as a copy, not a link: `bin/links.zsh install`
copies it with sudo, and `bin/links.zsh check` reports when it is missing or
differs from the repo file. keyd runs as root and runs `command(...)` actions
as root, so a link to a file the user owns would let any user process gain
root. After editing `default.conf`, run `bin/links.zsh install` and
`sudo keyd reload`.

`keyd-application-mapper` rereads `app.conf` at the next focus change after
the file changes.

Any member of the `keyd` group can make keyd send arbitrary keys with
`keyd bind`.

## Check

```sh
systemctl status keyd
gnome-extensions info keyd@keyd.rvaiya.github.com   # State: ACTIVE
pgrep -af keyd-application-mapper
tail -f ~/.config/keyd/app.log
```

To see the class of each window that gets focus, stop the daemon and run the
mapper in the foreground:

```sh
pkill -f keyd-application-mapper
keyd-application-mapper -v
```

## Uninstall

```sh
gnome-extensions disable keyd@keyd.rvaiya.github.com
sudo systemctl disable --now keyd
sudo rm /etc/keyd/default.conf
sudo dnf remove keyd
sudo dnf copr disable alternateved/keyd
```
