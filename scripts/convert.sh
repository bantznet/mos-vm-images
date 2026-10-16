#!/usr/bin/env bash
# Convert the raw image into portable formats. Usage: convert.sh <in.img> <outdir> <basename>
set -euo pipefail
IN=${1:?in.img}; OUTDIR=${2:?outdir}; NAME=${3:?name}
mkdir -p "$OUTDIR"
qemu-img convert -f raw -O vmdk -o subformat=streamOptimized "$IN" "$OUTDIR/$NAME.vmdk"
qemu-img convert -f raw -O vhdx "$IN" "$OUTDIR/$NAME.vhdx"
qemu-img convert -f raw -O qcow2 -c "$IN" "$OUTDIR/$NAME.qcow2"
