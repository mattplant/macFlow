# macFlow Reference Context

Reference documentation for the `macFlow` project.

## Design Philosophy

The core objective is to decouple the *Development Workflow* from the host *Operating System*. We treat the machine as two distinct entities working in tandem.

### Stability & Host Integrity

The foundational goal is to maintain the reliability of modern Apple Silicon and the macOS ecosystem for everyday use, while leveraging Linux VM(s) for development.

- **Host Integrity:** We keep macOS as the stable host for **critical functions** (Hardware drivers, Battery life, Wi-Fi stability) and high-performance native apps (Zoom, Teams, Office).
- **VM Performance:** We ensure the Linux environment remains lightweight and disposable.

## The Bridge (Integration Points)

To ensure a seamless flow, `macFlow` uses standard protocols to bypass driver limitations on Apple Silicon:

- **Files:** macOS `~/macFlow` directory is mounted into the VM via **SSHFS**.
- **Clipboard:** Copy/Paste is handled via **SPICE** (Desktop Mode) or **SSH** (Headless Mode).
- **Identity:** Git credentials are passed via **SSH Agent Forwarding** (Headless Mode).

## Modes

`macFlow` supports two distinct operating modes.

- **"Headless" Mode:** No Linux GUI. You use macOS native terminals and VSCode Remote to interact with the Linux engine. Extremely lightweight, max battery efficiency, zero maintenance, native macOS fonts/rendering. For more info, see [macFlow Headless](./Headless.md).
- **"Desktop" Mode:** A full Tiling Window Manager environment inside the VM. The complete tiling experience (Dwindle layout), distraction-free focus. For more info, see [macFlow Desktop](./Desktop.md).

*Tip:* You can start with "Headless" for lightweight tasks, and switch to "Desktop" mode later if needed.

## Arch Linux Configuration Build notes

Build notes for configuring various components of `macFlow` for use with [UTM](./VM/UTM.md) on macOS.

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

### Install and Configure Drivers

Since we are running on UTM (QEMU), we need specific drivers for 3D acceleration (`virtio-gpu`), clipboard synchronization (`spice`), and host communication.

#### Install Packages

```bash
# - mesa: 3D acceleration (virtio-gpu)
# - linux-headers: Kernel headers for module compilation
yay -S mesa linux-headers
```

#### Configure Kernel (mkinitcpio)

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

#### Enable Services

Ensure background agents start on boot.

```bash
# Enable QEMU Guest Agent for Host-Guest communication
sudo systemctl start qemu-guest-agent
```

### Install and Enable SSH

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

#### Generate your SSH key

```bash
# Generate Key (if you haven't already)
ssh-keygen -t ed25519 -C "macflow"
```

### Install GNU Stow

Install `stow` to manage dotfiles and configurations.

```bash
sudo pacman -S stow
```

## Directory Structure

```text
macFlow/
├── docs/               # Documentation
│   ├── Guest-OS/       # Arch Linux installation and configuration
│   ├── Integration/    # SSH, SSHFS, and Bridge configuration
│   ├── Tools/          # VSCode, git config, etc.
│   ├── VM/             # UTM configuration
│   ├── WM/             # Hyprland and Waybar configuration
│   ├── Desktop.md      # Desktop Mode documentation
│   ├── Headless.md     # Headless Mode documentation
│   ├── Reference.md    # Hyprland and Waybar configuration
│   └── Tips.md         # Tips & Tricks
├── dotfiles/            # Source configuration files (Stow targets)
├── scripts/            # Installation and setup scripts
├── LICENSE             # Source Code License (MIT)
├── LICENSE-DOCS.md     # Documentation License (CC BY 4.0)
└── README.md           # You are here
```
