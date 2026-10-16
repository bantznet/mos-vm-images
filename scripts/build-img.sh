#!/usr/bin/env bash
# Build a raw MOS boot image: MBR + one FAT32 partition labeled MOS, release ZIP extracted at root.
# Usage: build-img.sh <mos-release.zip> <out.img> [size]   (needs sudo: losetup/mount)
set -euo pipefail
ZIP=${1:?zip}; OUT=${2:?out.img}; SIZE=${3:-16G}

rm -f "$OUT"
truncate -s "$SIZE" "$OUT"
parted -s "$OUT" mklabel msdos mkpart primary fat32 1MiB 100% set 1 boot on

LOOP=$(sudo losetup -fP --show "$OUT")
MNT=$(mktemp -d)
cleanup() { sudo umount "$MNT" 2>/dev/null || true; sudo losetup -d "$LOOP" 2>/dev/null || true; rmdir "$MNT" 2>/dev/null || true; }
trap cleanup EXIT

sudo mkfs.vfat -F 32 -n MOS "${LOOP}p1" >/dev/null
sudo mount "${LOOP}p1" "$MNT"
sudo unzip -q "$ZIP" -d "$MNT"

# Release ZIP must extract to the volume root; flatten if it came wrapped in one folder.
if [ "$(sudo ls -A "$MNT" | wc -l)" -eq 1 ] && [ -d "$MNT/$(sudo ls -A "$MNT")" ]; then
  d="$MNT/$(sudo ls -A "$MNT")"
  sudo sh -c "mv '$d'/* '$d'/.[!.]* '$MNT'/ 2>/dev/null || true; rmdir '$d'"
fi
sudo ls -la "$MNT"
sync
