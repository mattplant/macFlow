# macFlow: UTM

Build notes for using UTM for virtualization in the `macFlow` project.

We use UTM because it exposes standard Linux hardware (`virtio`) that has excellent upstream support in Arch Linux ARM and uses Apple `Virtualization.framework` for near-native speed.

## Dowloand Arch Linux's Archboot ISO

We use the **Archboot** ISO instead of the official tarball because it provides an interactive installer (`archboot-setup`) and bootable structure suitable for VMs.

- **Download:** [Archboot AArch64 ISO](https://release.archboot.com/aarch64/latest/iso/)

## Install UTM

Download from [mac.getutm.app](https://mac.getutm.app/)

Or if you use Homebrew:

```bash
brew install --cask utm
```

> *Note:* This installs the free, fully-featured version (supports JIT/Hypervisor).

## Create the Virtual Machine

- Open UTM and click `Create a New Virtual Machine`
- **Start**
  - Select `Virtualize` (*Uses Apple `Virtualization.framework` for near-native speed*)
  - Select `Linux`
- **Hardware**
  - **Memory:** `8192 MB` (*8 GB*)
  - **CPU Cores:** `4`
  - *Note:* You can adjust this later based on performance needs.

- **Linux**
  - *Uncheck* "Use Apple Virtualization" (This forces QEMU backend, which has better Linux driver support).
  - Click `Browse` and select your `archboot-*.iso`.
- **Storage**
  - Size: `40 GB`
- **Shared Directory**
  - Leave empty for now (We will stick to SSHFS for consistency, or configure VirtFS later).
- **Summary**
  - **Name:** `macFlow`
  - **Notes:** `Arch Linux from Archboot AArch64 ISO`
  - **Check** "Open VM Settings"
  - Click `Save`

## Critical Configuration (The Secret Sauce)

In the Settings window that appears:

- **Display (Enable 3D):**
  - **Emulated Display Card:** Select `virtio-gpu-gl-pci`.
    - *Why:* This card supports OpenGL hardware acceleration using the Apple Metal backend.
  - Check **Retina Mode**
    - *Why:* High DPI when using Hyprland
- **Network:**
  - **Network Mode:** `Bridged (Advanced)`
  - *Why:* Allows the VM to have its own IP for SSH access (`macflow.local`) and seamless and reliable SSH file sharing.

## Continue to Arch Linux Installation

Follow the steps in [Arch Linux ARM Installation](../Guest-OS/Arch.md) to start the Linux installation.
