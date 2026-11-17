#!/usr/bin/env zsh
#
# Regenerate src/ for a kernel version: upstream hid-magicmouse.c and hid-ids.h,
# then the t2linux patches that touch them, then patches/*.patch.
#
#   ./update-source.zsh 7.3.3
#
# Run it when a new kernel changes the driver; a patch that no longer applies
# stops the script and leaves src/ unchanged.

emulate -LR zsh
setopt err_exit pipe_fail

(( $# == 1 )) || { print -r -u2 "usage: ${0:t} <kernel version, e.g. 7.3.3>"; exit 2 }
local version=$1
local here=${0:A:h}
local stable=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain
local t2=https://raw.githubusercontent.com/t2linux/linux-t2-patches/main
# t2linux patches that change hid-magicmouse.c or hid-ids.h
local -a t2_patches=(
  4001-asahi-trackpad.patch
  4004-HID-magicmouse-Add-support-for-trackpads-found-on-T2.patch
)
local -a files=(drivers/hid/hid-magicmouse.c drivers/hid/hid-ids.h)

local work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p $work/tree/drivers/hid
cd $work/tree

local f p
for f in $files; do
  curl -fsSL -o $f "$stable/$f?h=v$version"
done
git init -q
git add -A
git -c user.name=update-source -c user.email=none -c commit.gpgsign=false commit -qm "v$version"

local -a include=(${files/#/--include=})
local -a am=(git -c user.name=update-source -c user.email=none -c commit.gpgsign=false am -q $include)
for p in $t2_patches; do
  curl -fsSL -o $work/$p "$t2/$p"
  $am $work/$p
done
for p in $here/patches/*.patch; do
  $am $p
done

cp $files $here/src/
print -r -- "src/ regenerated for v$version"
