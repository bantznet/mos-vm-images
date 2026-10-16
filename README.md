# mos-vm-images

[![Build](https://github.com/bantznet/mos-vm-images/actions/workflows/build.yml/badge.svg)](https://github.com/bantznet/mos-vm-images/actions/workflows/build.yml)
[![Latest image](https://img.shields.io/github/v/release/bantznet/mos-vm-images?label=latest%20image)](https://github.com/bantznet/mos-vm-images/releases/latest)
[![MOS upstream](https://img.shields.io/github/v/release/mos-nas/mos-releases?label=upstream%20MOS)](https://github.com/mos-nas/mos-releases/releases)
![UEFI only](https://img.shields.io/badge/boot-UEFI%20only-blue)
![Formats](https://img.shields.io/badge/formats-OVA%20%7C%20VMDK%20%7C%20qcow2-lightgrey)

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
| `.qcow2` | Proxmox / KVM |
| `.img.xz` | raw disk, anything else |

## How to test MOS on various virtualization platforms

Grab the files from the [Releases](../../releases) page. **These steps are untested on some platforms; boot reports welcome.**
All platforms need: 
- **UEFI/EFI on, Secure Boot off**
- 4+ GB RAM (8 recommended)
- 2+ CPUs
- a SATA (or NVMe) boot disk,
- extra blank virtual disks if you want to try pools. 
After boot, find the VM's IP and open `http://<vm-ip>/` to set passwords.

### VirtualBox (Windows / Linux / Intel Mac)
[Download VirtualBox](https://www.virtualbox.org/wiki/Downloads) | [Manual](https://www.virtualbox.org/wiki/Documentation)

1. Download `mos-<version>-amd64.ova`.
2. **File -> Import Appliance**, pick the OVA, and import it (defaults are fine).
3. **Before the first boot:** select the VM -> Settings -> **System -> Motherboard -> tick _Enable EFI_.** VirtualBox ignores the OVA's UEFI setting, so without this the VM will not boot.
4. Settings -> **Network -> Adapter 1 -> Bridged Adapter**. Use wired Ethernet if possible; bridging over Wi-Fi often fails.
5. Optional: add blank virtual disks (Settings -> Storage) if you want to try storage pools.
6. Start the VM and **wait 1-3 minutes.** The window is blank or looks frozen while MOS boots. When it finishes, the console shows a login prompt with the VM's address, e.g. `IPv4: 192.168.1.164`.
7. Open `http://<that address>/` in a browser and set the account passwords.

`smartd failed` in the boot log is expected in a VM.

*Using the `.vmdk` instead (untested):* VirtualBox's Import Appliance only takes OVA/OVF, so create the VM with **Machine -> New**
(Linux, Other Linux 64-bit, tick *Enable EFI*), and attach the VMDK under **Settings -> Storage -> SATA controller -> Add Hard Disk -> Choose existing**.

### VMware Workstation (tested) / Fusion / ESXi (untested)
[Workstation & Fusion product page](https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion) | [How to download (free for personal use)](https://knowledge.broadcom.com/external/article/368667/download-and-license-vmware-desktop-hype.html)

**Workstation Pro:** **File -> Open** the `.ova` (or double-click it) and import it. UEFI, the SATA disk and the network adapter are
already set in the OVA, so no settings need changing. Use a bridged network adapter, power on, and wait 1-3 minutes; the console
shows the VM's `IPv4:` address. Open `http://<that address>/`.

**Fusion (Mac) and ESXi** should import the same OVA but are untested. On ESXi, if the OVA import complains, upload the `.vmdk`, run
`vmkfstools -i mos.vmdk -d thin mos-esx.vmdk`, and attach it to a new UEFI VM (SATA controller, `e1000e` NIC).

### Proxmox VE (tested)
Run these in the **Proxmox host shell**. They download the latest image, verify it, build a UEFI VM and attach the disk.

```bash
# 1. Download the latest .qcow2 + checksums, and verify
cd /var/tmp
curl -fsSL https://api.github.com/repos/bantznet/mos-vm-images/releases/latest \
  | grep -oE 'https://[^"]+(\.qcow2|SHA256SUMS)' | xargs -n1 curl -fLO
sha256sum -c --ignore-missing SHA256SUMS

# 2. Create the VM (UEFI, Secure Boot keys NOT pre-enrolled)
VMID=$(pvesh get /cluster/nextid)
STORAGE=local-lvm        # any storage that holds VM disks (e.g. local-lvm, nvme-ceph)
qm create $VMID --name mos --machine q35 --bios ovmf --cpu host --cores 4 --memory 8192 \
  --ostype l26 --scsihw virtio-scsi-single --net0 virtio,bridge=vmbr0 \
  --efidisk0 $STORAGE:1,efitype=4m,pre-enrolled-keys=0

# 3. Import the image and attach it as the boot disk, plus a blank 32 GB disk to play with
qm importdisk $VMID /var/tmp/mos-*-amd64.qcow2 $STORAGE
DISK=$(qm config $VMID | awk -F'[ ,]' '/^unused0/{print $2}')
qm set $VMID --scsi0 "$DISK" --scsi1 $STORAGE:32 --boot order=scsi0

# 4. Start it and note its MAC address
qm start $VMID
qm config $VMID | grep -o 'virtio=[^,]*'
```

Then wait 1-3 minutes. The Proxmox console can look garbled; that is cosmetic and MOS is still booting. Find the VM's address from
its MAC in your router's DHCP leases (or `ping` sweep your subnet and check `ip neigh`), then open `http://<address>/` and set the passwords.
Use **Install to Disk** in the MOS UI onto the blank disk if you want it independent of the boot image.

To remove the test VM: `qm stop $VMID && qm destroy $VMID --purge`.

*Other KVM setups:* the same qcow2 works with libvirt/virt-manager (UEFI/OVMF firmware, Secure Boot off, SATA or virtio disk).

### Hyper-V (Windows): not currently supported
A tester running MOS under Hyper-V reported that it starts, then stops in its initramfs with
`ERROR: MOS boot device with label: MOS not found`. The likely cause (inferred from the kernel config, not yet confirmed upstream):
the MOS kernel is built without Hyper-V support
(`# CONFIG_HYPERV is not set` in [mos-kernel](https://github.com/mos-nas/mos-kernel/blob/master/kernel-config/config)),
so it cannot see Hyper-V's VMBus/SCSI disks. Generation 1 VMs are BIOS-only while MOS requires UEFI.
This needs an upstream change to the MOS kernel. On a Windows PC, use VirtualBox or VMware Workstation instead (both tested above).

### Tips
- The console can look blank, frozen or garbled for the first minute or two. Wait; the login banner shows the VM's IPv4 address.
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
Not affiliated with the MOS project. ESXi and Fusion are **untested**; Hyper-V is **not supported** (see above).
MOS components are under their own licenses; see the upstream repo.

## License
The build scripts and workflow in this repo are [MIT licensed](LICENSE). MOS itself and the images it produces
contain components under their own licenses; see the [upstream repo](https://github.com/mos-nas/mos-releases).
