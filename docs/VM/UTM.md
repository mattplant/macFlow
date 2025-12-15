# macFlow: UTM

Build notes for using **UTM** for virtualization in the `macFlow` project.

We use **UTM** because it exposes standard Linux hardware (`virtio`) that has excellent upstream support in Arch Linux ARM and uses Apple `Virtualization.framework` for near-native speed.

## Download Installation Media

Use the **Archboot** ISO instead of the official tarball because it provides an interactive installer (`archboot-setup`) and bootable structure suitable for VMs.

- **Download:** [Archboot AArch64 ISO](https://release.archboot.com/aarch64/latest/iso/)
  - *Tip:* Download the file named `archboot-...-aarch64.iso` (avoid the `-local` version to ensure fresh packages).

## Install UTM

Download from [mac.getutm.app](https://mac.getutm.app/) or use Homebrew:

```bash
brew install --cask utm
```

> *Note:* This installs the free, fully-featured version (supports JIT/Hypervisor), which is preferred over the App Store version for this workflow.

## Create the Virtual Machine

Open UTM and click `Create a New Virtual Machine`.

- **Start**
  - Select `Virtualize` (*Uses Apple `Virtualization.framework` for near-native speed*)
  - Select `Linux`
- **Hardware**
  - **Memory:** `8192 MB` (*8 GB*)
  - **CPU Cores:** `4`
  - *Note:* You can adjust this later based on performance needs.
- **Linux**
  - **Uncheck** "Use Apple Virtualization"
    - *Why:* This forces QEMU backend, which has better Linux driver support.
  - Click `Browse` and select your `archboot-*.iso`.
- **Storage**
  - Size: `40 GB`
- **Shared Directory**
  - Leave empty
    - *Note:* We use SSHFS for robust file sharing.
- **Summary**
  - **Name:** `macFlow`
  - **Notes:** `Arch Linux from Archboot AArch64 ISO for macFlow`
  - **Check** "Open VM Settings"
  - Click `Save`

## Critical Configuration (The Secret Sauce)

In the Settings window that appears, apply these specific changes to support Hyprland on Apple Silicon:

- **Display (Enable 3D):**
  - **Emulated Display Card:** Select `virtio-gpu-gl-pci`.
    - *Why:* This card supports OpenGL hardware acceleration using the Apple Metal backend without the legacy framebuffer conflicts of `ramfb`.
  - Verify that `GPU Acceleration Supported` is checked.
  - Check `Resize display to window size automatically`
    - *Why:* Allows the SPICE agent to dynamically resize the VM resolution when you resize the UTM window.
  - **Upscaling:** Set to `Linear` if you want to allow fractional scaling.
  - Check `Retina Mode`
    - *Why:* Required to unlock resolutions higher than 1280x800 (HiDPI).
- **Network:**
  - **Network Mode:** `Bridged (Advanced)`
  - *Why:* Gives the VM a distinct IP address on the LAN, allowing for seamless SSH connections and reliable file mounting.

## Serial (Crucial for Installation)

Since the `virtio-gpu-pci` card does not display boot text until the kernel loads, we need a **Serial Console** to interact with the installer.

- **New Device:** Click New... (bottom of sidebar) > Serial
- **Mode:** Select Built-in Terminal
- *Note:* You will use this text window to run the `archboot` installer. You can remove this device after the OS is installed.

## Continue to Arch Linux Base Installation

Follow the steps in [Arch Linux (ARM) Install](../Guest-OS/Arch-Install.md) for the base installation of Arch Linux for macFlow.
