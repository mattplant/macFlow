# macFlow: Arch Linux (ARM) Configuration

Build notes and troubleshooting documentation for configuring **Arch Linux ARM (ALARM)** for use with [UTM](../VM/UTM.md) on macOS.

## Boot Arch Linux

- **Start the VM** in UTM.
- **Boot:** Select `Arch Linux` from the GRUB menu.

## Basic System Configuration

We need to establish `sudo` and a readable font before tackling drivers.

### Configure Sudo

You cannot run admin commands yet. Switch to root to fix permissions.

```bash
# Switch to root
su -

# Install Sudo and Editor
pacman -S sudo

# Configure Permissions
EDITOR=nano visudo
# Action: Find and uncomment the line: %wheel ALL=(ALL:ALL) ALL
# (Press Ctrl+O to save, Ctrl+X to exit)

# Add user to wheel group
usermod -aG wheel macflow

# Return to standard user
exit
```

## Clone macFlow

Ensure you have cloned the repo into your home directory:

```bash
cd ~
git clone https://github.com/mattplant/macFlow.git
```

## Configure Arch Linux

Run the macFlow Arch configuration script to automate the setup of drivers, packages, and services.

```bash
~/macFlow/scripts/configArch.sh
```

## Explanation of Key Steps

### Package Management (yay)

Install `yay` to simplify and expand package management.

#### Why `yay`?

- **Access to AUR:** Required for packages not in the official ARM repos (specifically **VSCode ARM64** binaries and proprietary fonts).
- **Unified Workflow:** `yay` mirrors `pacman` syntax for updates and installation
- **Automation:** Handles cloning, compiling, and dependency resolution automatically

#### Pre-requisites

Ensure the core build tools are installed.

```bash
# Install prereqs
# - base-devel: Required for building AUR packages
# - git: Required for cloning the yay repository
sudo pacman -S --needed base-devel git
```

#### Installation

We must compile `yay` manually once to bootstrap it.

*Note:* Do not run makepkg as root. Run these commands as your standard user (macflow).

```bash
# Clone and Build
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

#  Cleanup
cd ..
rm -rf yay
```

## Install and Configure Drivers

Since we are running on UTM (QEMU), we need specific drivers for 3D acceleration (`virtio-gpu`), clipboard synchronization (`spice`), and host communication.

### Install Packages

```bash
# - mesa: 3D acceleration (virtio-gpu)
# - linux-headers: Kernel headers for module compilation
yay -S mesa linux-headers
```

### Configure Kernel (mkinitcpio)

**Critical Step:** **We must force the kernel to load the `virtio-gpu` module early in the boot process or the screen will remain black.

```bash
sudo nano /etc/mkinitcpio.conf
# Action: Find the MODULES=() line and add the following: virtio virtio_pci virtio_blk virtio_net virtio_gpu
# e.g. MODULES=(btrfs vfat crc32c virtio virtio_pci virtio_blk virtio_net virtio_gpu)
# Save and Exit

# Regenerate images:
sudo mkinitcpio -P
```

### Enable Services

Ensure background agents start on boot.

```bash
# Enable QEMU Guest Agent for Host-Guest communication
sudo systemctl start qemu-guest-agent
```

## Install and Enable SSH

Install OpenSSH

```bash
yay -S openssh
```

Prevent the root user from logging in remotely

```bash
sudo nano /etc/ssh/sshd_config
```

Enable SSH service now and on boot

```bash
sudo systemctl enable --now sshd
```

## Install GNU Stow

Install `stow` to manage dotfiles and configurations.

```bash
sudo pacman -S stow
```
