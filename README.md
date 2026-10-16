# mos-vm-images

[![Build](https://github.com/bantznet/mos-vm-images/actions/workflows/build.yml/badge.svg)](https://github.com/bantznet/mos-vm-images/actions/workflows/build.yml)
[![Latest image](https://img.shields.io/github/v/release/bantznet/mos-vm-images?label=latest%20image)](https://github.com/bantznet/mos-vm-images/releases/latest)
[![MOS upstream](https://img.shields.io/github/v/release/mos-nas/mos-releases?label=upstream%20MOS)](https://github.com/mos-nas/mos-releases/releases)
![UEFI only](https://img.shields.io/badge/boot-UEFI%20only-blue)
![Formats](https://img.shields.io/badge/formats-OVA%20%7C%20VMDK%20%7C%20VHDX%20%7C%20qcow2-lightgrey)

> [!IMPORTANT]
> **These images are for trying MOS in a virtual machine only.** They are unofficial, built by a third party, and not
> supported by the MOS project. To run MOS for real (on bare metal or as a long-term server), follow the official
> instructions: [Create Bootable Media](https://docs.mos-official.net/docs/Installation/Create-Bootable-Media/) and the
> [MOS documentation](https://docs.mos-official.net/). Report MOS bugs upstream at
> [mos-nas/mos-releases](https://github.com/mos-nas/mos-releases), and image-build problems here.

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

## Try it on desktop VM software

Grab the files from the [Releases](../../releases) page. **These steps are untested on most platforms; boot reports welcome.**
All platforms need: **UEFI/EFI on, Secure Boot off**, 4+ GB RAM (8 recommended), 2+ CPUs, a SATA (or NVMe) boot disk,
and extra blank virtual disks if you want to try pools. After boot, find the VM's IP and open `http://<vm-ip>/` to set passwords.

### VirtualBox (Windows / Linux / Intel Mac)
[Download VirtualBox](https://www.virtualbox.org/wiki/Downloads) | [Manual](https://www.virtualbox.org/wiki/Documentation)

1. Download `mos-<version>-amd64.vmdk` (or `.vhdx`).
2. **New** VM -> Type *Linux*, Version *Other Linux (64-bit)*, 8 GB RAM, 4 CPUs. Choose *Do not add a virtual hard disk*.
3. Settings -> **System -> Motherboard -> Enable EFI**.
4. Settings -> **Storage -> SATA controller -> Add hard disk -> Choose existing** -> pick the VMDK. Add blank disks the same way.
5. Settings -> **Network -> Bridged Adapter** (adapter type *Intel PRO/1000*). With NAT, add a port-forward from host port 8080 to guest port 80 and browse `http://localhost:8080/`.
6. Start the VM and wait ~1-3 minutes. The console may be garbled or blank; that's cosmetic. Find the IP in your router's DHCP leases.

### VMware Workstation / Fusion / ESXi
[Workstation & Fusion product page](https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion) | [How to download (free for personal use)](https://knowledge.broadcom.com/external/article/368667/download-and-license-vmware-desktop-hype.html). Downloads need a free Broadcom account.

Import the `.ova` (File -> Open, or *Deploy OVF* on ESXi). On ESXi, if the OVA import complains, upload the `.vmdk`, run
`vmkfstools -i mos.vmdk -d thin mos-esx.vmdk`, and attach it to a new UEFI VM (SATA controller, `e1000e` NIC).

### Hyper-V (Windows)
[Enable Hyper-V on Windows](https://learn.microsoft.com/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v)

Create a **Generation 2** VM, attach the `.vhdx` as its disk, and **disable Secure Boot** (Security -> uncheck *Enable Secure Boot*).

### Proxmox / KVM
Import the `.qcow2` (`qm importdisk <vmid> mos.qcow2 <storage>`) into a q35 + OVMF VM with Secure Boot keys not pre-enrolled.

### Tips
- First boot can show a garbled console; the system is still booting. Use the WebUI.
- The VM's IP can change after "Install to Disk" or a reboot; reserve it in your DHCP server.
- Use **Install to Disk** in the MOS UI to a blank virtual disk if you'd rather not boot from the image.

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

## License
The build scripts and workflow in this repo are [MIT licensed](LICENSE). MOS itself and the images it produces
contain components under their own licenses; see the [upstream repo](https://github.com/mos-nas/mos-releases).
