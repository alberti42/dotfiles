#!/bin/bash
# DKMS PRE_BUILD: put the amdgpu source of a kernel into ./src, patched as
# that kernel was built, then patches/*.patch on top.
#
#   prepare-source.sh <kernel release, e.g. 7.3.3-310.t2.fc45.x86_64>
#
# The source comes from the kernel's Copr source package: linux-<ver>.tar.xz,
# then the amdgpu parts of patch-*-redhat.patch, t2linux-combined.patch and
# linux-kernel-test.patch, in the order kernel.spec applies them. The source
# package is downloaded once per kernel into $CACHE.

set -euo pipefail

kver=${1:?usage: prepare-source.sh <kernel release>}
COPR_OWNER=sharpenedblade
COPR_PROJECT=t2linux
CACHE=/var/cache/amdgpu-s2idle
here=$(pwd)
amd='drivers/gpu/drm/amd/*'

# kernel-7.3.3-310.t2.fc45.src.rpm -> version 7.3.3-310.t2 (Copr drops the dist tag)
srpm=$(rpm -q --qf '%{SOURCERPM}' "kernel-core-$kver")
version=${srpm#kernel-}
version=${version%.src.rpm}
version=${version%.fc*}
echo "prepare-source: kernel $kver, source package version $version"

mkdir -p "$CACHE"
file=$CACHE/kernel-$version.src.rpm
if [ ! -s "$file" ]; then
    url=$(curl -fsSL "https://copr.fedorainfracloud.org/api_3/build/list/?ownername=$COPR_OWNER&projectname=$COPR_PROJECT&packagename=kernel&limit=100" |
        python3 -I -c '
import json, sys
want = sys.argv[1]
for b in json.load(sys.stdin)["items"]:
    if b["state"] == "succeeded" and b["source_package"]["version"] == want:
        print(b["source_package"]["url"])
        break
' "$version")
    [ -n "$url" ] || { echo "prepare-source: no succeeded Copr build of kernel $version" >&2; exit 1; }
    echo "prepare-source: downloading $url"
    curl -fsSL -o "$file.part" "$url"
    mv "$file.part" "$file"
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
(cd "$work" && rpm2cpio "$file" | cpio -idm --quiet './linux-*.tar.xz' './*.patch')
tarball=$(ls "$work"/linux-*.tar.xz)
top=$(basename "$tarball" .tar.xz)

rm -rf src
mkdir -p src
tar -xJf "$tarball" -C src --strip-components=1 \
    --wildcards "$top/drivers/gpu/drm/amd/*" "$top/drivers/gpu/drm/*.h" "$top/drivers/gpu/drm/display/*"

cd src
for p in "$work"/patch-*-redhat.patch "$work"/t2linux-combined.patch "$work"/linux-kernel-test.patch; do
    [ -e "$p" ] || continue
    echo "prepare-source: applying the amdgpu parts of $(basename "$p")"
    git apply --allow-empty --include="$amd" "$p"
done
for p in "$here"/patches/*.patch; do
    echo "prepare-source: applying $(basename "$p")"
    git apply "$p"
done

# amdgpu_trace.h names its location relative to the kernel source tree
# (../../drivers/gpu/drm/amd/amdgpu); MAKE adds -I src/include/trace.
mkdir -p include/trace
echo "prepare-source: done"
