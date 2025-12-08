# macFlow: Fusion

Build notes for using VMware Fusion for virtualization in the `macFlow` project.

## Install VMware Fusion (*now free*)

Download VMware Fusion from their [website](https://www.vmware.com/products/fusion.html).

*Note that you will need to register for a free account, but the license for personal and business use is now free.*

And install it by following the standard macOS application installation process.

## Configure the Image in VMware Fusion

### Initial Setup

- Click `File` > `New` > `Create a custom virtual machine`
- Drag the `archboot-*.iso` into the installation media area
- Click `Continue`
- **Operating System:** Select `Linux` > `Other Linux 6.x kernel 64-bit Arm`
- Click `Continue` > `Customize Settings`.
- **Save As:** `macFlow.vmwarevm` in `~/Virtual Machines/`

### Hardware Configuration

#### General

- **Name:** `macFlow`
- **Notes:** `Arch Linux from Archboot AArch64 ISO`

#### Processors & Memory

- **Processors:** `4` cores
- **Memory:** `8192` MB (8 GB)
  - *You can adjust this later based on performance needs.*

#### Display (Crucial for M4)

- **Accelerate 3D Graphics:** `CHECKED`
  - *Why:* Even though we force Software Rendering (`pixman`) later, the `vmwgfx` kernel driver often fails to report high resolutions if this "switch" is off in the firmware.
- **Shared Graphics Memory:** `256 MB`
  - *Why:* Since the CPU does the rendering, VRAM is only a framebuffer. 256 MB is sufficient for a double-buffered 4K screen.
- **Retina:** `Check "Use full resolution for Retina display"`
  - *Result:* The VM will render at HiDPI (e.g., 3024x1964). We will handle the scaling inside Sway/Hyprland.

#### Network

- **Type:** `Bridged Networking > Autodetect`
- *Why:* Gives the VM its own IP address on your LAN, making SSH file sharing seamless and reliable.

#### Hard Disk (NVMe)

- **Disk Size:** `40 GB` (Required for BTRFS snapshots + Development tools)
- Under `Advanced options`
- **Bus type:** `NVMe`
  - *Why:* NVMe is significantly faster than SATA on Apple Silicon.
- **Pre-allocate disk space:** `Unchecked`
  - *Why:* Saves disk space on the host until needed.
- **Split into multiple files:** `Unchecked`
  - *Why:* Single file is better for macOS Time Machine performance.
- *Note:* The drive will appear as `/dev/nvme0n1` in Linux, not `/dev/sda`.

#### CD/DVD

- **Connect CD/DVD Drive:** `CHECKED`
- **Image:** Select the `archboot-*.iso` you downloaded earlier
- **Bus:** `SATA` *(Default)*

#### Startup Disk

- Select  `CD/DVD`

## Continue to Arch Linux Installation

Follow the steps in [Arch Linux ARM Installation](../Guest-OS/Arch.md) to start the Linux installation.
