# macFlow: Arch Linux Configuration

Configure **Arch Linux ARM (ALARM)** for use with [UTM](../VM/UTM.md) on macOS.

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

Clone the macFlow repo into your home directory:

```bash
sudo pacman -S git
cd ~
git clone https://github.com/mattplant/macFlow.git
```

## Execute Script to Configure Arch Linux

Run the `macFlow` Arch Linux configuration script to automate the setup of drivers, packages, and services.

```bash
~/macFlow/scripts/configArch.sh
```
