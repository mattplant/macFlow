# macFlow: Arch Linux with VMware Fusion

> NOTE: We were unable to get Hyprland working using VMware Fusion on Apple Silicon (M4) due to fundamental compatibility issues with the graphics stack.
>
> See [Arch](./Arch-Install.md) for installing Arch Linux ARM on alternate VM platform.

---
---

# Original Arch Linux Notes

Build notes and troubleshooting documentation for installing **Arch Linux ARM (ALARM)**.

## Installation Media

We use the **Archboot** ISO instead of the official tarball because it provides an interactive installer (`archboot-setup`) and bootable structure suitable for VMs.

- **Download:** [Archboot AArch64 ISO](https://release.archboot.com/aarch64/latest/iso/)
- **Mounting:** In VMware Fusion > `macFlow` VM > `Settings` > `CD/DVD`:
  - Check **"Connect CD/DVD Drive"**
  - Under `Advanced options`
    - Set `Device type` to **SATA** (Crucial for ARM compatibility)
- Close Settings

### Initial Boot

- Start the VM

## Core Installation (Archboot)

- From the `GNU Grub` menu
  - Select `Launch UEFI Archboot - Arch Linux aarch64`
- From the Archboot menu
  - You will see a text screen listing features (Vconsole, Wi-Fi, Quickinst, etc.).
  - Press `ENTER` to login
    - This logs you in as root and automatically starts the Archboot Launcher/Setup Menu.
    - For `Locale` select `en-US English`
    - For `Network Interface` select `enp2s0`
    - For `Network Profile Name` go with the default of 'enp2S0-ethernet'
      - This sets the `Network profile` to `/etc/systemd/network/enp2s0-ethernet.network`
    - For `Network Configuration` select `DHCP`
    - Leave the `Proxy Configuration` blank
  - On `Summary` screen, review settings and select `Yes` to apply.
  - Select a local mirror when prompted.

### Partitioning (Quick Setup)

From the Launcher Menu, select **`Quick Setup`**

- **Disk:** `/dev/nvme0n1`
- **Device Name Scheme:** `FSUUID` *(Industry standard for persistent block device naming)*
- **EFI System Partition (ESP):** `/boot (single boot)`
  - **EFI Size:** `1024 MB`
  - **Swap:** `0` *(we won't use swap)*
  - For `File System and Home` select `BTRFS`
    - Confirm using BTFRFS with selecting `Yes`
  - For `/ in MiB` enter `0` *(Uses whats left of the disk)*
  - Confirm using "dev/nvme0n1" to wipe and partition

### Package Selection

From the Launcher Menu, select **`Install Packages`**

- Confirm installation of these required packages for minimum system by selecting `Yes`
  - `iptables-nft` - firewall utilities
  - `polkit` - privilege management
  - `btrfs-progs` - BTRFS filesystem tools
  - `dosfstools` - DOS filesystem utilities
  - `terminal-fonts` - console fonts

### Configuration

From the Launcher Menu, select **`Configure System`**

- **Root Password:** Set root password
- **Default Editor:** Select `Nano` (easy for beginners or whatever you prefer)
- **Init System:** Select `systemd` (mkinitcpio will be configured automatically)
- **Shell:** Select `bash`
- **User:** Create your user (e.g., `macflow`)
- go thru each system config option and accept defaults except where called out below:
  - for hostname set to `macflow`
  - for additional packages add
    - `base-devel` - development tools (sudo, gcc, make, etc.)
    - `git` - version control

### Install Bootloader

- Select `Install Bootloader` from the Archboot "Setup Menu"
  - For `AA64 UEFI Bootloader` select `GRUB_UEFI`
    - *WHy?* Safer recovery method, easy confiig format and snapshot (future proofing)

### Finish Installation

From the Launcher Menu, select **`Exit Menu`

- Select `Poweroff System`
  - *Why?* This provides a clean stop, allowing you to eject the ISO from VMware settings so your first boot actually goes to your new Arch Linux hard drive.`
- Prevent the VM from booting back into the Archboot ISO:
  - Go to `Virtual Machine` > `Settings` > `CD/DVD`
  - Uncheck **"Connect CD/DVD Drive"**
  - Start the VM again

## Post-Install Configuration

### Network & Sudo

```bash
# Login as the user you created (e.g., macflow)

# Enable Networking (*If not already active*)
sudo systemctl enable --now NetworkManager

# Verify Connectivity
ping -c 3 archlinux.org
```

### Make Console Font Readable

The TTY is currently rendering at native 4K resolution (microscopic text). We need to install and configure a specialized HiDPI console font (Terminus).

```bash
# Install Terminus Font
sudo pacman -Syu terminus-font

# Edit vconsole.conf
sudo nano /etc/vconsole.conf
# Set: FONT=ter-132n

# Apply immediately
sudo systemctl restart systemd-vconsole-setup
```

### Install base-devel and git

If you missed selecting `base-devel` and `git` during the installation, fix it now by temporarily switching to the root user.

TODO: Verify that we can remove this step if we selected during install.

```bash
# Switch to root
su -

# Install core development tools (if missing)
pacman -Syu base-devel git

# Configure Sudo
EDITOR=nano visudo
# Action: Find and uncomment the line: %wheel ALL=(ALL:ALL) ALL
# (Press Ctrl+O to save, Ctrl+X to exit)

# Ensure your user is in the wheel group
# Replace 'macflow' with your actual username if you used a different one
usermod -aG wheel macflow

# Return to your standard user
exit
```

### Package Management: Installing `yay`

While `pacman` is the official package manager for Arch Linux, we install `yay` to simplify and expand package management.

#### Why `yay`?

- **Access to AUR:** Required for packages not in the official ARM repos (specifically **VSCode ARM64** binaries and proprietary fonts).
- **Unified Workflow:** `yay` mirrors `pacman` syntax. You can use it for everything (system updates, searching, installing).
- **Automation:** It handles the complex process of cloning `git` repos, compiling code (`makepkg`), and installing dependencies automatically.

#### Installation

We must compile `yay` manually once to bootstrap it.

```bash
# Clone and Install
cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Cleanup
cd ..
rm -rf yay
```

### Harden Time Sync

VMware Tools provides basic time synchronization, but it can lag when the host macOS wakes from sleep. To make the clock bulletproof, we enable the native Linux Network Time Protocol (NTP) service as a backup.

```bash
# Enable systemd-timesyncd service
sudo systemctl enable --now systemd-timesyncd
```

## VMware Integration and Drivers

### Install open-vm-tools (Build from Source)

We install `open-vm-tools` to enable **Time Synchronization** (critical for git/ssl), **Power Management** (clean shutdowns from the Fusion menu), and to assist the kernel with display state.

*Note:* The standard `pacman -S open-vm-tools` fails on ARM because it is missing from the official ALARM repositories. We must compile it using the official Arch Linux build scripts.

```bash
# Install Build Dependencies
# mesa: Required for OpenGL headers
# gtkmm3/gtk3: Required for the userspace plugins to compile
# libx*: Required for resolution helper libraries
sudo pacman -S --needed mesa gtkmm3 gtk3 libxtst libxinerama libxrandr

# Clone the Official Arch Linux Package Source
cd ~
git clone https://gitlab.archlinux.org/archlinux/packaging/packages/open-vm-tools.git
cd open-vm-tools

# Patch for ARM Support
# The official package is restricted to x86_64. We add 'aarch64' to the allow list.
sed -i "s/arch=('x86_64')/arch=('x86_64' 'aarch64')/" PKGBUILD

# Build and Install
makepkg -si
```

### Enable Services

Start the `open-vm-tools` background service that communicates with the host.

```bash
# Main tools daemon
# Handles Time Sync, Graceful Power Operations (Shutdown/Reboot), and OS Heartbeat.
# (Note: Clipboard and Auto-Resolution will be handled later via SSH/Manual Config due to missing VMCI drivers)
sudo systemctl enable --now vmtoolsd
```

### Verification

Verify that the `open-vm-tools` service is running and the kernel has loaded the graphics drivers correctly.

```bash
# Check Service Status
# Look for 'Active: active (running)' in green
systemctl status vmtoolsd

# Check Graphics Driver
# You should see 'vmwgfx' listed. This confirms the kernel sees the display adapter.
lsmod | grep vmwgfx

# Verify Graphics Hardware
# Should report: "VMware SVGA II Adapter (Fusion)"
lspci -k | grep -A 2 -E "VGA|3D|Display"
```

## Architecture Constraints: The VMCI Gap

A core constraint of running Arch Linux ARM on VMware Fusion (Apple Silicon) is the absence of the `vmw_vmci` driver.

The **Virtual Machine Communication Interface** (`vmw_vmci`) is VMware's proprietary driver for high-speed host-guest communication. It is **not included** in the default kernel builds for Arch Linux ARM. Without this driver, the `open-vm-tools` features that rely on a direct line to the Host OS will not function:

- **Clipboard Sync:** Sending text/images between macOS and Linux memory buffers.
- **Auto-Resolution:** Sending the signal *"The window size just changed"* so the Guest can reflow instantly.
- **Drag and Drop:** Moving files across the VM border via the GUI.
- **Unity Mode:** (On Windows/Intel) Allowing Guest apps to float on the Host desktop.

### The "Air-Gapped" UI Consequence

Because `vmw_vmci` is missing, the GUI effectively operates in an "Air-Gapped" state regarding data transfer:

| Feature           | Status        | Workaround                                                    |
| :---------------- | :------------ | :------------------------------------------------------------ |
| **Data Exchange** | ❌ **Broken**  | Clipboard and File Sharing handled via **SSH** and **SSHFS**. |
| **Auto-Resize**   | ❌ **Broken**  | Resolution must be set manually (see below).                  |
| **Video Output**  | ✅ **Working** | `vmwgfx` driver handles rendering.                            |
| **Input**         | ✅ **Working** | Standard USB Mouse/Keyboard emulation.                        |
