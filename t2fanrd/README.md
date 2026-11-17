# t2fanrd: quieter fan curves on the iMac Pro

`t2fanrd` (installed from the t2linux Copr, service `t2fanrd.service`) sets the
speed of the iMac Pro's two fans through the SMC driver (`macsmc_hwmon`,
`fan1_target` and `fan2_target`). `t2fand.conf` replaces the default curves:

| Key | Default | Here |
|---|---|---|
| `low_temp` | 55 | 60 |
| `high_temp` | 75 | 85 |
| `speed_curve` | `linear` | `exponential` |

Below `low_temp` a fan runs at its minimum, 1100 rpm; above `high_temp` at its
maximum, 2500 rpm (`fan*_min` and `fan*_max` in the SMC). With `exponential`
the speed stays low longer and rises steeply near `high_temp`. At idle nothing
changes: the fans already run at the 1100 rpm minimum.

The program's own documentation is `/usr/share/doc/t2fanrd/README.md`; it
lists the keys and the three curves, `linear`, `exponential` and
`logarithmic`.

## Which temperature

`t2fanrd` reads the CPU package temperature
(`/sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input`, critical at
100 °C) and a GPU temperature at `/sys/class/drm/card0/device/hwmon/hwmon*/temp1_input`.
On the iMac Pro the Radeon Pro Vega is `card1` and there is no `card0`, so the
fans follow the CPU temperature only. Under GPU-only load they rise only as
far as the CPU warms up; amdgpu throttles the GPU when it gets too hot.

## Install

`links.conf` lists the file as a copy:

```sh
~/.config/dotfiles/bin/links.zsh install
sudo systemctl restart t2fanrd
```

`t2fanrd` reads the file at start, so restart it after each change.

## Check

```sh
journalctl -u t2fanrd -b | grep -E 'low_temp|high_temp|speed_curve'
cat /sys/class/hwmon/hwmon*/fan*_input
```
