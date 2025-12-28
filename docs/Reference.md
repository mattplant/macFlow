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

## Linux Installation Notes

Key components with context of the `macFlow` Arch Linux installation.

- Required packages for for minimum system:
  - `base` - core OS
  - `iptables-nft` - firewall utilities
  - `linux` - Linux kernel
  - `polkit` - privilege management
  - `btrfs-progs` - BTRFS filesystem tools
  - `dosfstools` - DOS filesystem utilities
  - `terminal-fonts` - console fonts
- We also installed these modules: `virtio virtio_pci virtio_blk virtio_net virtio_gpu`

## Linux Configuration Notes

Key components with context of the `macFlow` Arch Linux configuration.

*Note:* Do not run makepkg as root. Run these commands as your standard user (macflow).

### Package Management (yay)

Install `yay` to simplify and expand package management.

#### Why `yay`?

- **Access to AUR:** Required for packages not in the official ARM repos (specifically **VSCode ARM64** binaries and proprietary fonts).
- **Unified Workflow:** `yay` mirrors `pacman` syntax for updates and installation
- **Automation:** Handles cloning, compiling, and dependency resolution automatically

#### Pre-requisites

Ensure the core build tools are installed.

```bash
# - base-devel: Required for building AUR packages
# - git: Required for cloning the yay repository
sudo pacman -S --needed base-devel git
```

#### Installation

We must compile `yay` manually once to bootstrap it.

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
# qemu-guest-agent: Host communication
# openssh: Remote access
# avahi, nss-mdns: Hostname resolution (.local)
yay -S mesa linux-headers qemu-guest-agent openssh avahi nss-mdns
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
# Enable Avahi Daemon (Bonjour) for .local hostname resolution
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

Enable QEMU Guest Agent and SSH Services.

```bash
sudo systemctl start qemu-guest-agent
sudo systemctl enable --now sshd
```

#### Generate your SSH key

Generate a SSH keypair on your the Linux VM using the modern, fast Edwards-curve (ed25519) algorithm. This creates two files in ~/.ssh/ directory:

- **id_ed25519** - Private Key - KEEP SECRET
- **id_ed25519.pub** - Public Key - Shared with Host

```bash
ssh-keygen -t ed25519 -C "macflow-vm"
# (Accept the default location/name so it is used automatically)
# (Leave passphrase empty for passwordless login)
```

### Install GNU Stow

Install `stow` to manage dotfiles and configurations.

```bash
sudo pacman -S stow
```

### Deploy Configurations

We use `stow` to symlink configuration the **Dot Files** for `macFlow`'s components including:

- Shell profile (`.bash_profile`, `.zshrc`)
- Utility scripts (`~/bin/`)
- Foot (Terminal Emulator)
- Hyprland (Tiling Window Manager) and its components

### Configure the Guest side of the File Bridge (SSHFS)

#### Setup Passwordless Access (SSH Keys)

For the mount to work automatically, the Linux VM must log in to the Mac without a password prompt.

#### Configure SSH Host Alias

Create a config entry so you can simply refer to your Mac as `host`.

Add the following block to your SSH config (e.g. ```nano ~/.ssh/config```) with your macOS details:

```text
Host host
    HostName MyMac.local
    User matt
    IdentityFile ~/.ssh/id_ed25519
```

#### Copy Public Key to macOS

Run this command from your Linux VM to authorize your key. Replace the placeholders with your actual macOS details.

```bash
ssh-copy-id host
```

#### Install and Configure the SSH filesystem (SSHFS) driver

Install the driver and perform a manual mount to verify everything is working:

```bash
sudo pacman -S sshfs
```

Enable `user_allow_other` option (Required for permission mapping)

```bash
# Open the FUSE config file
sudo nano /etc/fuse.conf
# Uncomment the line: user_allow_other
```

#### Setup Persistence (The `macmount` Utility)

Instead of hardcoding the mount into startup scripts (which can hang boot if the network is down), we use a resilient shell function. This allows you to mount the drive from Hyprland or TTY.

Add this to your shell profile (`~/.bash_profile`):

```bash
# --- macFlow: SSHFS Mount Utility ---
# Usage: Type 'macmount' to connect, 'macunmount' to disconnect

function macmount() {
    local MOUNT_POINT="$HOME/macFlow-HOST"
    local REMOTE_PATH="macFlow-SHARE" # Relative to your Mac Home folder

    # 1. Safety Check: Is it already mounted?
    if mount | grep -q "$MOUNT_POINT"; then
        echo "⚡ macOS is already mounted at $MOUNT_POINT"
        return 0
    fi

    # 2. Ensure mount point exists
    if [ ! -d "$MOUNT_POINT" ]; then
        echo "Creating mount point: $MOUNT_POINT"
        mkdir -p "$MOUNT_POINT"
    fi

    # 3. Cleanup stale connections (force unmount if stuck)
    if [ -e "$MOUNT_POINT" ]; then
        fusermount3 -u "$MOUNT_POINT" 2>/dev/null
    fi

    # 4. Mount macOS Shared Folder
    echo "Connecting to macOS Host..."
    # - Syntax: sshfs [alias]:[remote_path] [local_path] [options]
    #   - host: The alias we configured in ~/.ssh/config above
    #   - remote_path: /Users/matt/macFlow-SHARE
    #   - local_path: ~/macFlow-HOST
    #   - options:
    #     - 'allow_other': allows other users (root) to see files
    #     - 'reconnect': automatically restores connection after sleep/resume
    #     - `uid=$(id -u),gid=$(id -g)`: ensures the files appear as owned by your linux user
    sshfs "host:$REMOTE_PATH" "$MOUNT_POINT" -o allow_other,reconnect,uid=$(id -u),gid=$(id -g)

    # 5. Verify result
    if [ $? -eq 0 ]; then
        echo "✅ Success: Shared folder mounted."
    else
        echo "❌ Error: Could not connect to Host. Check network or SSH config."
    fi
}

function macunmount() {
    fusermount3 -u ~/macFlow-HOST
    echo "Disconnected from macOS."
}
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
