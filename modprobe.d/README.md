# modprobe.d

## `blacklist-applesmc.conf`

On the iMac Pro (iMacPro1,1) with the t2linux Fedora kernel 7.3.3, the `macsmc_*`
drivers talk to the T2's SMC, and `t2fanrd` controls the fans through them
(`Enabled macsmc fan control support`). The older `applesmc` driver fails on
this machine:

```
applesmc applesmc.768: probe with driver applesmc failed with error -5
applesmc: driver init failed (ret=-5)!
```

udev loads it 3 to 4 times per boot, about 50 s apart. While a `udev-worker`
waits in `applesmc_init`, it does not freeze, and a suspend requested at that
moment aborts:

```
Freezing user space processes failed after 20.004 seconds (1 tasks refusing to freeze, wq_busy=0):
task:(udev-worker) ...
 applesmc_init+0x105/0xff0 [applesmc]
```

`blacklist applesmc` stops udev from loading it.

### Install

```sh
~/.config/dotfiles/bin/links.zsh install
```

`links.conf` lists the file as a copy, not a link: `bin/links.zsh install`
copies it with sudo, and `bin/links.zsh check` reports when it is missing or
differs from the repo file. It takes effect at the next boot.

### Check

After a reboot:

```sh
lsmod | grep -c '^applesmc'                 # 0
journalctl -b -k | grep -c 'applesmc.*fail' # 0
```

### Uninstall

```sh
sudo rm /etc/modprobe.d/blacklist-applesmc.conf
```
