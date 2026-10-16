# mos-vm-images

Unofficial pipeline that turns the official [MOS](https://github.com/mos-nas/mos-releases) release ZIP
into ready-to-import VM disk images.

| Format | For |
|---|---|
| `.ova` / `.vmdk` | ESXi / VMware |
| `.vhdx` | Hyper-V |
| `.qcow2` | Proxmox / KVM |
| `.img.xz` | raw disk, anything else |

Requirements for the VM: **UEFI firmware, Secure Boot off**, 4+ GB RAM (8 recommended), SATA or NVMe disk,
an emulated NIC (e1000e) plus extra disks for pools. Then open `http://<vm-ip>/`.

## How the image is built
MOS boots from a FAT32 volume labeled `MOS` with the release ZIP extracted at its root
([docs](https://docs.mos-official.net/docs/Installation/Create-Bootable-Media/)).
`scripts/build-img.sh` makes that volume inside an MBR-partitioned raw image; `scripts/convert.sh`
and `scripts/make-ova.sh` convert/package it; `scripts/smoke-test.sh` boots it under QEMU+OVMF and waits for the WebUI.

## Local build
    sudo apt install qemu-utils qemu-system-x86 ovmf parted dosfstools unzip jq
    ./scripts/build-img.sh mos_x.y.z_amd64.zip mos.img
    ./scripts/smoke-test.sh mos.img
    ./scripts/convert.sh mos.img dist mos
    ./scripts/make-ova.sh dist/mos.vmdk dist/mos.ova x.y.z

## Status
Not affiliated with the MOS project. ESXi/Hyper-V boot is **untested** unless noted in a release.
MOS components are under their own licenses; see the upstream repo.
