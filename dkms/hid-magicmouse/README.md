# hid-magicmouse: scrolling and clicks closer to macOS

This DKMS package builds the driver with three changes ([patches/](patches/)).

**Scrolling.** Moving an Apple Magic Mouse also slides the finger a little on
its touch surface. macOS ignores that; Linux's `hid_magicmouse` driver turns it
into scroll events, so moving the pointer to a link often scrolls the page too.
With the patch, the movement in each report is read before the touches,
and while the mouse moved within the last `scroll_motion_block_ms`, finger
motion does not scroll. The scroll position follows the finger meanwhile, so
nothing accumulated is released when the mouse stops.

**Clicks.** The mouse has one switch; the driver decides which button a click
is. Upstream, it uses the position of the only "firm" touch (contact size 8 or
more), and otherwise keeps the mouse's own guess. With the hand resting on the
mouse, the fingers on the right half are often that firm touch, and a left
click with the index finger becomes a right click. With `click_priority_side`
set, the driver looks at all touches, as macOS does: with `1`, a touch on the
left half (x < 0) makes a left click, so a right click needs all fingers on the
right half; `2` mirrors this for the left hand. With `emulate_3button`, touches
only in the middle zone (−350 to +350) still make a middle click.

**Momentum.** The driver stops scrolling the moment the finger leaves the
surface; GNOME and GTK add momentum only to touchpad scrolling, never to a
wheel. With `scroll_momentum_ms` set, a finger that leaves the surface while
scrolling faster than 700 units/s (10 mm/s vertically), and that moved within
the last 50 ms, keeps the page scrolling: every 8 ms a timer sends high-resolution
wheel events, and the speed decays exponentially with time constant
`scroll_momentum_ms`, until it drops below 100 units/s. A new touch, a click,
or scrolling with another finger stops it. The scroll distance after the lift
is the lift speed times `scroll_momentum_ms`. 500 ms, the deceleration rate of
iOS scroll views (0.998 per ms), glides too far on the Magic Mouse;
`hid-magicmouse.conf` sets 175 ms.

| Module option | Default | Meaning |
|---|---|---|
| `scroll_motion_block_ms` | `0` (off, upstream behaviour) | ignore scrolling for this many ms after the mouse moved |
| `scroll_motion_threshold` | `2` | movement per report (\|dx\|+\|dy\|) above which the mouse counts as moving; raise it if hand jitter interrupts deliberate scrolling |
| `scroll_momentum_ms` | `0` (off, upstream behaviour) | after a fast scroll, keep scrolling and slow down with this time constant in ms |
| `click_priority_side` | `0` (off, upstream behaviour) | `1`: a touch on the left half makes a left click (right hand); `2`: a touch on the right half makes a right click (left hand) |

Only the Magic Mouse (1, 2, USB-C) is affected; trackpads never set the motion
time and never call the click code. All options can be changed at runtime:

```sh
echo 150 | sudo tee /sys/module/hid_magicmouse/parameters/scroll_motion_block_ms
```

## Source

`src/` is the driver as built in the t2linux Fedora kernel (Copr
`sharpenedblade/t2linux`): upstream `drivers/hid/hid-magicmouse.c` and
`hid-ids.h` at the kernel version, plus the t2linux patches that touch them
(`4001-asahi-trackpad`, `4004-HID-magicmouse-Add-support-for-trackpads-found-on-T2`),
plus `patches/*.patch`. Current base: **v7.3.3**.

The source is frozen at that base: DKMS builds this same copy for every later
kernel, not the kernel's own driver. So when a kernel update changes the driver
(a fix, a new device) the build still succeeds but misses the change, and when
it changes an internal kernel interface the build fails and the stock driver
(with stray scrolling) loads instead. After a kernel update, `dkms status`
should list the new kernel as `installed`.

When a kernel update changes the driver, regenerate it:

```sh
./update-source.zsh 7.3.4
```

then rebuild: `sudo dkms remove hid-magicmouse-motion/1.0 --all`, and the
`dkms add` / `dkms install` lines below.

## Install

DKMS builds for each kernel that has its `kernel-devel` installed. The t2linux
Copr only keeps `kernel-devel` for its newest kernel, so build for that one
(here 7.3.3) and boot into it:

```sh
sudo dnf install dkms kernel-devel-7.3.3-310.t2.fc45.x86_64
sudo ln -s ~/.config/dotfiles/dkms/hid-magicmouse /usr/src/hid-magicmouse-motion-1.0
sudo dkms add hid-magicmouse-motion/1.0
sudo dkms install hid-magicmouse-motion/1.0 -k 7.3.3-310.t2.fc45.x86_64
~/.config/dotfiles/bin/links.zsh install   # copies hid-magicmouse.conf to /etc/modprobe.d/
```

`links.conf` lists the file as a copy, not a link: `bin/links.zsh install`
copies it with sudo, and `bin/links.zsh check` reports when it is missing or
differs from the repo file.

`/usr/src/hid-magicmouse-motion-1.0` links to this directory; DKMS copies it
into its own build tree for each build. From then on, `dnf` rebuilds the module
for every new kernel installed together with its `kernel-devel`.

After booting into that kernel, check that the patched module is loaded:

```sh
modinfo -n hid_magicmouse            # .../extra/hid-magicmouse.ko.xz
cat /sys/module/hid_magicmouse/parameters/scroll_motion_block_ms
```

## Uninstall

```sh
sudo dkms remove hid-magicmouse-motion/1.0 --all
sudo rm /usr/src/hid-magicmouse-motion-1.0 /etc/modprobe.d/hid-magicmouse.conf
sudo modprobe -r hid_magicmouse && sudo modprobe hid_magicmouse   # back to the stock driver
```
