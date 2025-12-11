# macFlow: Arch Linux with UTM (AArch64)

Build notes and troubleshooting documentation for installing **Arch Linux ARM (ALARM)**.

## Initial Boot

Boot the VM (`Play` button)

## "Display output is not active" Workaround

If when booting the Archboot ISO in UTM, you see the `Display output is not active.` error, then use the serial console to see the installer output.

- Open UTM, select your `macFlow` VM but do not start it yet.
- Click New... > Serial
- Select `Built-in Terminal`
- Click Save

When the VM boots, there will be a second window with the serial console.

## Core Installation (Archboot)

- From the `GNU Grub` menu
  - Select `Launch UEFI Archboot - Arch Linux aarch64`
- From the **Archboot** menu
  - You will see a text screen listing features (Vconsole, Wi-Fi, Quickinst, etc.).
  - Press `ENTER` to login
    - This logs you in as root and automatically starts Archboot Launcher/Setup.
    - For `Locale` select `en-US English`
    - For `Network Interface` select `enp0s1`
    - For `Network Profile Name` go with the default of 'enp0s1-ethernet'
      - This sets the `Network profile` to `/etc/systemd/network/enp0s1-ethernet.network`
    - For `Network Configuration` select `DHCP`
    - Leave the `Proxy Configuration` blank
  - On `Summary` screen, review settings and select `Yes` to apply.
  - Select a local mirror when prompted.

### Partitioning (Quick Setup)

- From the **Launcher** menu, select **`Launch Archboot Setup`**
  - From the **Setup** menu, select **`Prepare Storage Device`**
  - From the **Prepare Storage Device menu**, select **`Quick Setup`**
    - For the size of the disk, enter `40G` *(40 GB)*
      - *Note:* UTM uses a VirtIO disk that appears as `/dev/vda`
    - **Device Name Scheme:** `FSUUID` *(Industry standard for persistent block device naming)*
    - **EFI System Partition (ESP):** `/boot (single boot)`
      - **EFI Size:** `1024` *(1 GB)*
      - **Swap:** `0` *(we won't use swap)*
      - For `File System and Home` select `Btrfs`
        - Confirm using BTRFS by selecting `Yes`
      - For `/ in MiB` enter `0` *(Uses whats left of the disk)*
        - Confirm using whatever space is left by selecting `Yes`
      - Confirm wipe and partition of "/dev/vda" by selecting `Yes`

### Package Selection

From the **Launcher** menu, select **`Install Packages`**

- Confirm installation of these required packages for minimum system by selecting `Yes`
  - `base` - core OS packages
  - `iptables-nft` - firewall utilities
  - `linux` - Linux kernel
  - `polkit` - privilege management
  - `btrfs-progs` - BTRFS filesystem tools
  - `dosfstools` - DOS filesystem utilities
  - `terminal-fonts` - console fonts

### Configuration

From the **Launcher** menu, select **`Configure System`**

- **Root Password:** Set root password
- **Default Editor:** Select `Nano` (easy for beginners or whatever you prefer)
- **Init System:** Select `systemd` (mkinitcpio will be configured automatically)
- From the **System Configuration**` menu
  - For the **User Management** menu
    - For **Default Shell**, select `bash`
    - For **Create User Account**, enter `macflow`
      - Add to `wheel` group for sudo access
      - For comment, enter `macFlow is the best` or your full name :)
      - Enter and confirm user password
      - Return to `System Configuration`
    - Go thru each system config option and accept defaults except where called out below:
      - Set **System Hostname** to `macflow`
      - For **Network Hosts** (/etc/hosts) add this entry to bottom `127.0.0.1        macflow.localdomain macflow`
      - Return to `Main Menu`

### Install Bootloader

- Select `Install Bootloader` from the Archboot **Setup Menu**
  - For `AA64 UEFI Bootloader` select `GRUB_UEFI`
    - *WHy?* Safer recovery method, easy confiig format and snapshot (future proofing)

### Finish Installation

- From the **Setup Menu**, select **`Exit`
  - Select `Poweroff System`
    - *Why?* This provides a clean stop, allowing you to eject the ISO from VMware settings so your first boot actually goes to your new Arch Linux hard drive.`
- Prevent the VM from booting back into the Archboot ISO:
  - On the `macFlow` VM in UTM, expand out the `CD/DVD` section and click `Clear`

## Post-Install Configuration

- Start the VM again
- From the `GNU Grub` menu, select `Arch Linux`

### Font Rendering Fix

If your console text looks garbled then done't panic. It is a common issue with the default font and can easily fixed with these steps:

- Log in "Blindly"
  - You are being asked for your login. Enter `macflow` and press Enter
  - Type your password and press Enter
  - Type `reset` and press Enter (to clear any garbled text)

This is a temporary fix to for this session only. We will make a permanent below.

### Sudo Installation and Configuration

```bash
# Switch to root
su -

# Install sudo
pacman -Syu sudo

# Configure Sudo
EDITOR=nano visudo
# Action: Find and uncomment the line: %wheel ALL=(ALL:ALL) ALL
# (Press Ctrl+O to save, Ctrl+X to exit)

# Ensure your user is in the wheel group
usermod -aG wheel macflow

# Return to your standard user
exit
```

### Make Console Font Readable

Now we tell the system to use a font that supports High DPI (Retina) and standard encoding.

```bash
# Install Terminus Font
sudo pacman -Syu terminus-font

# Edit vconsole.conf
sudo nano /etc/vconsole.conf
# While we are at it we can double it for retina/4k display
# Set: FONT=ter-132n

# Apply immediately
sudo systemctl restart systemd-vconsole-setup
```

### Package Management: Installing `yay`

While `pacman` is the official package manager for Arch Linux, we install `yay` to simplify and expand package management.

#### Why `yay`?

- **Access to AUR:** Required for packages not in the official ARM repos (specifically **VSCode ARM64** binaries and proprietary fonts).
- **Unified Workflow:** `yay` mirrors `pacman` syntax. You can use it for everything (system updates, searching, installing).
- **Automation:** It handles the complex process of cloning `git` repos, compiling code (`makepkg`), and installing dependencies automatically.

#### Pre-requisites

Ensure the core build tools are installed.

```bash
# Install git and base-devel group
# --needed: Skips packages that are already up-to-date
sudo pacman -Syu --needed git base-devel
```

#### Installation

We must compile `yay` manually once to bootstrap it.

*Note:* Do not run makepkg as root. Run these commands as your standard user (macflow).

```bash
# \Clone the repository
cd ~
git clone https://aur.archlinux.org/yay.git

# Build and Install
cd yay
makepkg -si

#  Cleanup
cd ..
rm -rf yay
```

### Install UTM/QEMU Drivers

Since we are running on UTM (QEMU), we need specific drivers for 3D acceleration (`virtio-gpu`), clipboard synchronization (`spice`), and host communication.

### Install Packages

```bash
# - mesa: Provides the virtio-gpu driver for 3D acceleration
# - spice-vdagent: Handles Clipboard Sync and Auto-Resolution resizing
# - qemu-guest-agent: Allows UTM to send Shutdown/Reboot commands cleanly
yay -S mesa spice-vdagent qemu-guest-agent
```

#### Configure MKINITCPIO (The Boot Image)

We need to force the kernel to load the virtio-gpu module early in the boot process so it takes over the screen from the EFI framebuffer.

Edit the config:

```bash
sudo nano /etc/mkinitcpio.conf
# Add modules: Find the MODULES=() line and and add the following:
# virtio virtio_pci virtio_blk virtio_net virtio_gpu
# e.g. MODULES=(btrfs vfat crc32c virtio virtio_pci virtio_blk virtio_net virtio_gpu)
# Save and Exit.

# Regenerate images:
mkinitcpio -P
```

#### Enable Services

Enable the background daemons so they start automatically on boot.

```bash
# Enable QEMU Guest Agent for Host-Guest communication
#sudo systemctl start qemu-guest-agent

# Enable Spice Agent for Clipboard Sync and Auto-Resize
#sudo systemctl start spice-vdagentd
```

### Configure UTM for Graphics (The Switch)

Now that the drivers are installed, we must configure the VM to use the 3D-accelerated GPU.

- Poweroff the VM: `sudo poweroff`
- Open UTM Settings for the VM
  - Navigate to Display
  - Change Emulated Display Card to: `virtio-gpu-gl-pci`
    - *Why:* This card supports OpenGL hardware acceleration using the Apple Metal backend.
- Start the VM

*Note:* You should now see the boot text appear on the Main Window (graphical), not just the Serial console.

===

We need to undo the gfxterm change inside GRUB, but keep the console=tty1 change for the Linux Kernel. We want GRUB to be simple text (which works), but we want Linux to take over the screen once it loads.

---

CRITICAL: Driver Fix (Before Reboot)
Do not reboot yet. We need to ensure the new system has the graphics drivers installed so the main window works next time.

Select Shell (or "Exit to Shell") from the menu to get a command prompt (#).

Chroot into your new drive:

Bash

# The installer usually mounts target to /mnt
arch-chroot /mnt
Install Graphics Drivers:

Bash

pacman -S mesa
Force Drivers into Boot Image: Edit the initramfs config:

Bash

nano /etc/mkinitcpio.conf
Find MODULES=().

Change to: MODULES=(virtio virtio_pci virtio_blk virtio_net virtio_gpu)

Save and Exit.

Regenerate Boot Image:

Bash

mkinitcpio -P
Fix GRUB (Enable Graphics): Edit the GRUB config:

Bash

nano /etc/default/grub
Find GRUB_TERMINAL_OUTPUT=console.

Change to #GRUB_TERMINAL_OUTPUT=console (Comment it out).

Add/Uncomment GRUB_TERMINAL_OUTPUT=gfxterm.

Save and Exit.

Update GRUB: grub-mkconfig -o /boot/grub/grub.cfg

🏁 Finish
Type exit (to leave chroot).

Type poweroff.

UTM Settings: Remove the Serial device.

Start.

====

Previously I was missing linux-kernel headers which are required for some AUR packages.
# Force reinstall of kernel and firmware
pacman -S linux linux-firmware