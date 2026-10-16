#!/usr/bin/env bash
# Wrap a streamOptimized VMDK in an OVF and tar it into an OVA.
# Usage: make-ova.sh <disk.vmdk> <out.ova> <version>
set -euo pipefail
VMDK=${1:?vmdk}; OVA=${2:?ova}; VERSION=${3:?version}
HERE=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
NAME=$(basename "${OVA%.ova}")

cp "$VMDK" "$WORK/$NAME-disk1.vmdk"
FILESIZE=$(stat -c %s "$WORK/$NAME-disk1.vmdk")
CAPACITY=$(qemu-img info --output=json "$VMDK" | jq -r '.["virtual-size"]')

sed -e "s|@NAME@|$NAME|g" -e "s|@VERSION@|$VERSION|g" \
    -e "s|@VMDK@|$NAME-disk1.vmdk|g" -e "s|@FILESIZE@|$FILESIZE|g" \
    -e "s|@CAPACITY@|$CAPACITY|g" "$HERE/templates/mos.ovf" > "$WORK/$NAME.ovf"

# OVF descriptor must be the first member of the tar.
( cd "$WORK" && tar --format=ustar -cf "$OLDPWD/$OVA" "$NAME.ovf" "$NAME-disk1.vmdk" )
