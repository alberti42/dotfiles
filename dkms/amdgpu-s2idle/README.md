# amdgpu: post the ASIC after the reset on resume from s2idle

[patches/](patches/) fixes the resume of the iMac Pro's Radeon Pro Vega 64
(Vega 10, `1002:6860`) from suspend-to-idle. Without it the GPU stays dead
after the wake and the screen stays black. The commit message in the patch
describes the cause. See [../../systemd-sleep/README.md](../../systemd-sleep/README.md)
for the rest of the suspend setup.

## Source

The module must be built from the same `amdgpu` code as the kernel it is for.
`prepare-source.sh`, which DKMS runs before each build, takes it from that
kernel's Copr source package (`sharpenedblade/t2linux`):

1. `linux-<version>.tar.xz`: `drivers/gpu/drm/amd`, `drivers/gpu/drm/display`
   and the headers in `drivers/gpu/drm`;
2. the `amdgpu` parts of `patch-*-redhat.patch`, `t2linux-combined.patch` and
   `linux-kernel-test.patch`, in the order `kernel.spec` applies them;
3. `patches/*.patch`.

It finds the source package with `rpm -q --qf '%{SOURCERPM}' kernel-core-<kernel>`
and the Copr API, and downloads it once per kernel (about 170 MB) into
`/var/cache/amdgpu-s2idle/`. A build needs network access the first time, and
about 3 GB in `/var/lib/dkms/` while it runs.

The current t2linux patches on GitHub are not used: their 5K changes to
`dce110_hwseq.c` and the DP link training showed the Plymouth spinner twice,
once per half of the 5K panel.

When a kernel update changes `amdgpu` so that the patch no longer applies, the
build fails and the stock `amdgpu` loads instead, without the fix. After a
kernel update, `dkms status` should list the new kernel as `installed`.

## Install

DKMS builds for each kernel that has its `kernel-devel` installed (see
[../hid-magicmouse/README.md](../hid-magicmouse/README.md)):

```sh
sudo ln -s ~/.config/dotfiles/dkms/amdgpu-s2idle /usr/src/amdgpu-s2idle-1.0
sudo dkms add amdgpu-s2idle/1.0
sudo dkms install amdgpu-s2idle/1.0 -k $(uname -r)
sudo dracut -f
```

The build takes about 10 minutes. `/usr/src/amdgpu-s2idle-1.0` links to this
directory; DKMS copies it into its own build tree for each build. From then
on, `dnf` rebuilds the module for every new kernel installed together with its
`kernel-devel`.

After a reboot, check that the patched module is loaded:

```sh
modinfo -n amdgpu      # .../extra/amdgpu.ko.xz
```

## Uninstall

```sh
sudo dkms remove amdgpu-s2idle/1.0 --all
sudo rm /usr/src/amdgpu-s2idle-1.0
sudo dracut -f
sudo rm -rf /var/cache/amdgpu-s2idle
```
