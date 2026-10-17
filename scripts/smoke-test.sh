#!/usr/bin/env bash
# Boot the raw image headless under QEMU + OVMF and wait for the MOS WebUI. Usage: smoke-test.sh <mos.img>
set -euo pipefail
IMG=${1:?img}; PORT=${PORT:-8080}; TIMEOUT=${TIMEOUT:-300}
first() { for f in "$@"; do [ -f "$f" ] && { echo "$f"; return; }; done; echo "OVMF firmware not found" >&2; return 1; }
OVMF=$(first /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd)
VARS=$(mktemp); cp "$(first /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd)" "$VARS"
ACCEL=tcg; [ -w /dev/kvm ] && ACCEL=kvm

qemu-system-x86_64 -machine q35,accel=$ACCEL -cpu max -m 4096 -smp 2 -display none -serial file:/tmp/mos-serial.log \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF" -drive if=pflash,format=raw,file="$VARS" \
  -drive file="$IMG",format=raw,if=none,id=d0,snapshot=on -device ahci,id=ahci -device ide-hd,drive=d0,bus=ahci.0 \
  -netdev "user,id=n0,hostfwd=tcp::${PORT}-:80" -device e1000e,netdev=n0 &
QPID=$!; trap 'kill $QPID 2>/dev/null || true' EXIT

for ((t=0; t<TIMEOUT; t+=5)); do
  code=$(curl -s -m 3 -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/" || true)
  if [ "$code" = "200" ]; then echo "WebUI up after ~${t}s (accel=$ACCEL)"; exit 0; fi
  sleep 5
done
echo "WebUI did not come up within ${TIMEOUT}s (accel=$ACCEL)"; exit 1
