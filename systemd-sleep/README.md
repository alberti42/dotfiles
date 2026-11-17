# Suspend on the iMac Pro: s2idle

`s2idle.conf` sets `MemorySleepMode=s2idle`, so systemd-sleep writes `s2idle`
to `/sys/power/mem_sleep` before each suspend instead of using the kernel's
default, `deep` (ACPI S3).

Suspend works on the iMac Pro (iMacPro1,1, t2linux Fedora kernel 7.3.3) only
with all three of these:

| What | Where | Fixes |
|---|---|---|
| `MemorySleepMode=s2idle` | `s2idle.conf` in this directory | `deep` (S3) never resumes, even without amdgpu |
| `pcie_port_pm=off` | kernel command line | the machine hangs while suspending the devices (late/noirq step) when PCIe ports enter a low-power state |
| patched `amdgpu` | [`../dkms/amdgpu-s2idle`](../dkms/amdgpu-s2idle) | after s2idle the GPU stays dead and the screen black |

## Why

Investigation of 2026-11-15 and 2026-11-16, with netconsole to a second
machine and `pm_test`:

- **`deep` (S3).** A real `deep` suspend never came back, also with `amdgpu`
  blacklisted. `pm_test=devices` came back.
- **PCIe port power management.** Without `amdgpu`, `pm_test=platform` and a
  real `s2idle` hung on the way into sleep. With `pcie_port_pm=off`, both
  passed, and a USB key press woke the machine.
- **amdgpu.** A soc15 dGPU keeps its power in s2idle. On resume amdgpu resets
  it ("S3 suspend abort case") but does not post it again, so the PSP
  bootloader stays down (`PSP load sys drv failed!`). The reset also clears
  the config space of the GPU's display audio function (`0000:f3:00.1`);
  `snd_hda_intel` then gets Unsupported Request, and AER recovery fails the
  whole slot (`pci_channel_io_perm_failure`). The patch posts the ASIC after
  the reset and restores the audio function's config.

During suspend, the fans run faster than when the machine is awake.

## Install

```sh
~/.config/dotfiles/bin/links.zsh install
sudo grubby --update-kernel=/boot/vmlinuz-$(uname -r) --args=pcie_port_pm=off
```

`links.conf` lists the file as a copy, not a link: `bin/links.zsh install`
copies it with sudo, and `bin/links.zsh check` reports when it is missing or
differs from the repo file.
systemd-sleep reads it at each suspend.

## Check

After a suspend and resume:

```sh
journalctl -b -k | grep 'PM: suspend entry'    # PM: suspend entry (s2idle)
grep -o pcie_port_pm=off /proc/cmdline
```

## Uninstall

```sh
sudo rm /etc/systemd/sleep.conf.d/s2idle.conf
sudo grubby --update-kernel=/boot/vmlinuz-$(uname -r) --remove-args=pcie_port_pm=off
```
