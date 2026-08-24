# macFlow: UTM

Build notes for using **UTM** for virtualization in the `macFlow` project.

We use **UTM** because it exposes standard Linux hardware (`virtio`) that has excellent
upstream support in Arch Linux ARM, and because it runs QEMU with Apple's Hypervisor
framework (HVF) for near-native speed.

> *Note:* UTM offers two backends. We use **QEMU accelerated by HVF**, not Apple's
> `Virtualization.framework` — the QEMU backend has far better Linux driver support,
> which is why the setup below unchecks "Use Apple Virtualization".

## Download Installation Media

Use the **Archboot** ISO instead of the official tarball because it provides an interactive installer (`archboot-setup`) and bootable structure suitable for VMs.

- **Download:** [Archboot AArch64 ISO](https://release.archboot.com/aarch64/latest/iso/)
  - *Tip:* Download the file named `archboot-...-aarch64.iso` (avoid the `-local` version to ensure fresh packages).

## Install UTM

Download from [mac.getutm.app](https://mac.getutm.app/) or use Homebrew:

```bash
brew install --cask utm
```

> *Note:* These install the free, fully-featured version (supports JIT/Hypervisor), which is preferred over the App Store version for this workflow.

## Create the Virtual Machine

Open UTM and create a new VM with these settings:

- **Start**
  - Select `Virtualize` (*hardware-accelerated, as opposed to `Emulate`*)
  - Select `Linux`
- **Hardware**
  - **Memory:** `4096 MB` (*4 GB*)
    - *Headless Mode* runs comfortably in `2048 MB`; `4096 MB` is the practical
      minimum once Hyprland, a browser and VS Code are running in Desktop Mode.
  - **CPU Cores:** Leave at `Default` for now.
  - *Note:* You can adjust this later based on performance needs.
  - **Display Output**
    - Verify that `Enable display output` is checked.
    - Check `Enable hardware OpenGL acceleration`.
- **Linux**
  - **Uncheck** "Use Apple Virtualization"
    - *Why:* This forces QEMU backend, which has better Linux driver support.
  - **Boot Image Type:** Select `Boot from ISO image`
  - Click `Browse` and select the `archboot-...-aarch64.iso` you downloaded earlier.
- **Storage**
  - Size of drive: `32 GB`
- **Shared Directory**
  - Leave empty
    - *Note:* We use SSHFS for robust file sharing.
- **Summary**
  - **Name:** `macFlow`
  - **Check** "Open VM Settings"
  - Click `Save`

## Critical Configuration (The Secret Sauce)

In the **Settings** window that appears, apply these specific changes to support macFlow on Apple Silicon:

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
  - *Why:* Gives the VM its own IP on the LAN, so SSH and SSHFS work without port
    forwarding.
  - ⚠️ **Bridged networking is unreliable over Wi-Fi.** 802.11 will not relay frames
    for a second MAC address behind one association, so the VM may get a DHCP lease
    yet still be unreachable from your Mac. If `ping` to the VM fails while the VM
    itself has working internet, this is why — use Ethernet, or switch the VM to
    `Shared Network`.
  - ⚠️ **Give every cloned VM a unique MAC address.** UTM does *not* regenerate it
    when you clone a bundle. Two VMs sharing a MAC cannot run at the same time, and
    the symptom is a silent host-to-guest ARP failure that looks like a network bug.
- Click `Save`

## Continue to Arch Linux Base Installation

Follow the steps in [Arch Linux (ARM) Install](../Guest-OS/Arch-Install.md) for the base installation of Arch Linux for macFlow.
