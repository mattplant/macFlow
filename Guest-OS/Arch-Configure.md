# macFlow: Arch Linux (ARM) Configuration

Build notes and troubleshooting documentation for configuring **Arch Linux ARM (ALARM)** for use with [UTM](../VM/UTM.md) on macOS.

## Boot VM

- **Start the VM** in UTM.
- **Open Serial Console:** Use the text-based window (not the black graphical one).
- **Boot:** Select `Arch Linux` from the GRUB menu.

### Font Rendering Fix (Temporary)

If the text looks garbled due to encoding mismatches, you can login "Blindly" and reset the terminal.

- Type `macflow` and press **Enter**.
- Type your password and press **Enter**.
- Type `reset` and press **Enter**.

## Basic System Configuration

We need to establish `sudo` and a readable font before tackling drivers.

### Configure Sudo

You cannot run admin commands yet. Switch to root to fix permissions.

```bash
# Switch to root
su -

# Install Sudo and Editor
pacman -S sudo nano

# Configure Permissions
EDITOR=nano visudo
# Action: Find and uncomment the line: %wheel ALL=(ALL:ALL) ALL
# (Press Ctrl+O to save, Ctrl+X to exit)

# Add user to wheel group
usermod -aG wheel macflow

# Return to standard user
exit
```

### Configure Console Font

Install a HiDPI-friendly font so the text is readable on the Retina display.

```bash
# Install Terminus Font
sudo pacman -S terminus-font

# Configure System
sudo nano /etc/vconsole.conf
# Action: Set content to: FONT=ter-132n

# Apply immediately
sudo systemctl restart systemd-vconsole-setup
```

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
cd ~
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
# - spice-vdagent: Clipboard and auto-resolution resizing
# - qemu-guest-agent: Host-Guest communication
# - linux-headers: Kernel headers for module compilation
yay -S mesa spice-vdagent qemu-guest-agent linux-headers
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

### Configure Bootloader (GRUB)

We must stop GRUB from sending video to the Serial Port (ttyAMA0) and redirect it to the Screen (tty1).

Edit the GRUB config:

```bash
sudo nano /etc/default/grub
```

- Fix Kernel Output:
  - Find `GRUB_CMDLINE_LINUX_DEFAULT=...`
  - Coment it out: `#GRUB_CMDLINE_LINUX_DEFAULT=...`
  - Add: `GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet console=tty1"`
- Fix GRUB Output:
  - Find `GRUB_TERMINAL_OUTPUT=...`
  - Coment it out: `#GRUB_TERMINAL_OUTPUT=...`
  - Add: `GRUB_TERMINAL_OUTPUT=console`
- *Why:* Keeps the bootloader in text mode to avoid "EFI UGA" errors.
- Save and Exit

Update Bootloader:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Enable Services

Ensure background agents start on boot.

```bash
# Enable QEMU Guest Agent for Host-Guest communication
sudo systemctl start qemu-guest-agent

# Enable Spice Agent for Clipboard Sync and Auto-Resize
sudo systemctl start spice-vdagentd
```

## The Hardware Switch (Enable 3D Accelerated Graphics)

Now that the software is ready, we switch the virtual hardware to 3D mode.

- Poweroff the VM: `sudo poweroff`
- Open UTM Settings for the VM
  - Serial: Right-click the `Serial` device in the sidebar and click `Remove`
    - *Why:* This forces the VM to use the main window for output and removes the confusing second window.
- Start the VM

*Note:* You should now see the boot text appear on the Main Window (graphical), not just the Serial console.
