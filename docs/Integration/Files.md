# macFlow: File Integration

Notes for sharing the macOS files with the Linux VM.

## Shared Workspace (SSH Filesystem)

For a productive development flow, we need a shared workspace between macOS and the Linux VM.

We will use **SSHFS** (SSH Filesystem) for a seamless and reliable way to read/write files on the macOS host from within the Linux VM.

While VMware/UTM **Shared Folders** are easy, they often have issues with file permission bits (executable flags) and file-watching events (crucial for tools like git or hot-reloading web servers).

### Enable SSH on macOS Host

We need to allow the VM to "log in" to your Mac to read/write files.

- Open `System Settings` on macOS
- Go to `General` > `Sharing`
- Toggle `Remote Login` to ON
- Note the Local hostname (e.g. `myMac.local`)
- Click the `i` (Info) button next to it
  - Make sure `Allow disk access for remote users` is left **OFF**
  - Ensure your user is listed under `Allow access for`
- *Security Note:* Turn on firewall, hide macOS from network discovery, etc. as desired for security.

### Create the shared folder on macOS

Create the folder on your Mac that you want to share with the Linux VM. Avoid using system-protected folders like `Documents` or `Desktop`.

```bash
mkdir ~/macFlow-SHARE
```

### Setup Passwordless Access (SSH Keys) to the macOS Host

For file mounting to work automatically, the Linux VM must be able to log in to the Mac without typing a password. We use SSH Keys to achieve this securely.

#### Copy Public Key to macOS

This script logs into your Mac and adds your Public Key to the `~/.ssh/authorized_keys` file on the host.

*Note:* Replace `matt` with your macOS username and hostname that you noted above.

```bash
ssh-copy-id matt@MyMac.local
# (Type your Mac password one last time to authorize the copy)
```

#### Configure SSH Host Alias

Create a config entry so you can simply refer to your Mac as host.

Add the following block to your SSH config (e.g. ```nano ~/.ssh/config```) with your macOS username and hostname that you noted above:

```text
Host host
    HostName MyMac.local
    User matt
    IdentityFile ~/.ssh/id_ed25519
```

#### Test Passwordless SSH Login

Verify that you can log in without a password.

```bash
ssh host
```

### Mount your macOS folder in the Linux VM

Now we will install the driver and mount the folder manually once to verify it works.

```bash
# Install the SSH filesystem (SSHFS) driver
sudo pacman -S sshfs

# Enable user_allow_other (Crucial for proper permissions)
sudo nano /etc/fuse.conf
# Find and uncomment the line: user_allow_other

# Create the mount point on Linux
mkdir -p ~/macFlow-HOST

# Mount macOS Dev Folder
# - Syntax: sshfs [alias]:[remote_path] [local_path] [options]
#   - host: The alias we configured in ~/.ssh/config above
#   - remote_path: /Users/matt/macFlow-SHARE
#   - local_path: ~/macFlow-HOST
#   - "-o allow_other,reconnect,uid=$(id -u),gid=$(id -g)" - ensures the files appear as owned by your linux user
#     - The `reconnect` option helps maintain the connection if the network drops temporarily
sshfs host:/Users/matt/macFlow-SHARE ~/macFlow-HOST -o allow_other,reconnect,uid=$(id -u),gid=$(id -g)

# Verify the mount
ls -la ~/macFlow-HOST
# (You should see your Mac files owned by your Linux user)
```

### Setup Persistence (Shell Function)

Instead of hardcoding the mount into a specific window manager configuration, we will add a convenience function to the shell profile. This allows you to mount the drive from Hyprland or TTY.

Edit your profile (e.g. ```nano ~/.bash_profile```) and add this function block to the bottom:

```bash
# MacFlow: SSHFS Mount Utility
# Usage: Type 'macmount' to connect, 'macunmount' to disconnect
function macmount() {
    # Safety Check: Is it already mounted?
    if mount | grep -q "$HOME/macFlow-HOST"; then
        echo "⚡ macOS is already mounted at ~/macFlow-HOST"
        return
    fi

    # Ensure mount point exists
    mkdir -p ~/macFlow-HOST

    # Cleanup stale connections
    fusermount3 -u ~/macFlow-HOST 2>/dev/null

    # Mount using the SSH alias 'host'
    echo "Connecting to Host..."
    sshfs host:/Users/matt/macFlow-SHARE ~/macFlow-HOST \
        -o allow_other,reconnect,uid=$(id -u),gid=$(id -g)

    # 5. Verify
    if [ $? -eq 0 ]; then
        echo "✅ Success: ~/macFlow-SHARE mounted to ~/macFlow-HOST"
    else
        echo "❌ Error: Could not connect to Host."
    fi
}

function macunmount() {
    fusermount3 -u ~/macFlow-HOST
    echo "Disconnected from macOS."
}
```

Apply Changes immediately:

```bash
source ~/.bash_profile
```

Usage:

- To connect: **`macmount`**
- To disconnect: **`macunmount`**
