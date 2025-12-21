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

# Install Sudo
pacman -S sudo

# Configure Permissions
EDITOR=nano visudo
# Action: Find and uncomment the line: %wheel ALL=(ALL:ALL) ALL

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

TODO: Add modules and packages (on this page) to base Arch install if possible.

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

Install and enable the SSH daemon and Avahi (Bonjour) for simple hostname resolution.

```bash
sudo systemctl enable --now sshd

```bash
# Install packages
# - openssh: SSH server/client
# - avahi: Bonjour/mDNS service discovery
# - nss-mdns: Allows resolving .local hostnames via mDNS
yay -S openssh avahi nss-mdns

# Enable the SSH Server
sudo systemctl enable --now sshd

# Enable Avahi (Bonjour) for .local hostname resolution
sudo systemctl enable --now avahi-daemon

# Configure Name Resolution: To ensure Arch broadcasts its name correctly
# Edit the config
sudo nano /etc/nsswitch.conf
# Find the line: hosts: ...
# Ensure "mdns_minimal [NOTFOUND=return]" is present before resolve or dns.
# This is what it was before I modified it:
# hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
# And this is what it should be changed to:
# hosts: mymachines files myhostname mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns
```

### Generate your SSH key

```bash
# Generate Key (if you haven't already)
ssh-keygen -t ed25519 -C "macflow"
```

## Install GNU Stow

Install `stow` to manage dotfiles and configurations.

```bash
sudo pacman -S stow
```
