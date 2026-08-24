# macFlow: Arch Linux Configuration

Configure **Arch Linux ARM (ALARM)** for use with [UTM](../VM/UTM.md) on macOS.

## Boot Arch Linux

- **Start the VM** in UTM
- **Boot:** Select `Arch Linux` from the boot menu
  - *Manual installs use GRUB; [Packer-built images](../../packer/README.md) use systemd-boot. Either way, pick `Arch Linux`.*
- **Login:** Use the username ("macflow") and password you created during installation

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

> ⚠️ **Log out and back in before continuing.** Group membership is only applied at
> login, so your current shell does not know it is in `wheel` yet and `sudo` will
> still refuse. If you created `macflow` as an Administrator during installation it
> is already in `wheel` and this whole section is a no-op — check with `id -nG`.

## Clone macFlow

Clone the macFlow repo into your home directory:

```bash
sudo pacman -S git
cd ~
git clone https://github.com/mattplant/macFlow.git
```

## Execute Script to Configure Arch Linux

Run the `macFlow` configuration script. It installs Ansible, then applies
[`ansible/setup.yml`](../../ansible/setup.yml) to this machine — drivers, packages,
services, and dotfiles.

```bash
~/macFlow/scripts/configArch.sh
```

*Note:* The playbook is the same one the [Packer build](../../packer/README.md)
applies, so both install paths end up with an identical system. It is idempotent —
re-run this script any time to re-apply the configuration.

## Connect This VM to Your Mac

Everything above is unattended. Linking the VM to your Mac needs your input
(hostname, username, password), so it is a separate step:

```bash
~/macFlow/scripts/connect_mac.sh
```

It asks for your Mac's hostname and username, verifies it can actually reach your
Mac on port 22, and only then regenerates the VM's SSH host keys, writes the `host`
alias to `~/.ssh/config`, and authorizes this VM on your Mac. If anything is wrong it
aborts without changing a thing, so it is safe to re-run.

*Finding your Mac's hostname:* it is **not** the friendly name ("Matt's MacBook Air").
Run this on macOS and add `.local`:

```bash
# On your Mac
scutil --get LocalHostName    # e.g. CSW020  ->  enter CSW020.local
```

An IP address works too. The script offers a detected default where it can, so on a
re-run you can usually just press Enter.

*Before running it*, make sure on macOS that **Remote Login** is ON
(System Settings > General > Sharing) and that the shared folder exists:

```bash
# On your Mac
mkdir ~/macFlow-SHARE
```

For the full picture, see [macFlow Integration](../Integration/macFlow-Integration.md).
