# macFlow: File Integration

Build notes for connectiong sharing the macOS files with the Linux VM

## Shared Workspace (SSH Filesystem)

For a productive development flow, we need a shared workspace between macOS and the Linux VM.

We will use SSHFS (SSH Filesystem) for a seamless and reliable way to read/write files on the macOS host from within the Linux VM.

While VMware Shared Folders are easy, they often have issues with file permission bits (executable flags) and file-watching events (crucial for tools like git or hot-reloading web servers).

### Enable SSH on macOS Host

We need to allow the VM to "log in" to your Mac to read/write files.

- Open System Settings on macOS
- Go to General > Sharing
- Toggle Remote Login to ON
- Note the Local hostname (e.g. something.local)
- Click the "i" (Info) button next to it
  - Make sure "Allow disk access for remote users" is left **OFF**
  - Ensure your user is listed under "Allow access for"
- Turn on firewall, hide macOS from network discovery, etc. as desired for security.

### Create the shared folder on macOS

Create on your Mac that you want to share with the Linux VM. Avoid using system-protected folders like `Documents` or `Desktop`.  My suggestion is to go with a new  `macFlow` folder in your home directory.

```bash
mkdir ~/macFlow
```

### Mount your macOS folder in the Linux VM

```bash
# Install the SSH filesystem (SSHF) driver
sudo pacman -S sshfs

# Enable user_allow_other
sudo nano /etc/fuse.conf
# Find and uncomment the line #user_allow_other

# Create the mount point
mkdir -p ~/macFlow

# Mount macOS Dev Folder in the Linux VM
# - Syntax: sshfs [user]@[host]:[remote_path] [local_path] -o allow_other,uid=1000,gid=1000
#   - user = your macOS username (e.g. matt)
#   - host = IP address (e.g. 192.168.1.X) or hostname (e.g. Matts-Mac.local)
#   - remote_path = path on your Mac to mount (e.g., /Users/matt/macFlow)
#   - local_path = path in your Arch VM to mount to (e.g., ~/macFlow)
#     - Do not use a macOS security-protected folder like ~/Documents or ~/Desktop
#   - "-o allow_other,reconnect,uid=$(id -u),gid=$(id -g)" - ensures the files appear as owned by your linux user
#     - The `reconnect` option helps maintain the connection if the network drops temporarily
# - EXAMPLE (adjust for your details):
sshfs matt@Matts-Mac.local:/Users/matt/macFlow ~/macFlow -o allow_other,reconnect,uid=$(id -u),gid=$(id -g)
# type 'yes' to accept the fingerprint
# enter your macOS password when prompted

# Verify the mount by listing the contents of the mounted directory
ls ~/macFlow
```

### Setup Passwordless Access (SSH Keys) to the macOS Host

For file mounting to work automatically, the Linux VM must be able to log in to the Mac without typing a password. We use SSH Keys to achieve this securely.

```bash
# Generate a Keypair on your the Linux VM
# -t ed25519: Uses the modern, fast Edwards-curve algorithm
# This creates two files in ~/.ssh/:
#   - id_ed25519 (Private Key - KEEP SECRET)
#   - id_ed25519.pub (Public Key - Shared with Host)
ssh-keygen -t ed25519 -C "macflow-vm"
# (Accept the default location/name so it is used automatically)
# (Leave passphrase empty for passwordless login)

# Copy the Public Key to macOS
# This script logs into your Mac and adds your Public Key to the `~/.ssh/authorized_keys` file on the host.
# Replace 'matt' and 'Matts-M4.local' with your actual Mac details that you used above.
ssh-copy-id matt@Matts-Mac.local
# (Type your Mac password one last time to authorize the copy)

# Test Connection
ssh matt@Matts-M4.local
# (You should be logged in immediately without a password. Type 'exit' to return.)

# Now that passwordless SSH is set up, you can use the same `sshfs` command as before, just this time it will not require a password. No reason to test it again here since the files are already mounted.
```

### Setup Persistence (Shell Function)

Instead of hardcoding the mount into a specific window manager configuration, we will add a convenience function to the shell profile. This allows you to mount the drive from Sway, River, or even the TTY with a single command.

Edit your profile:

```bash
nano ~/.bash_profile
```

Add this function block to the bottom:

```bash
# MacFlow: SSHFS Mount Utility
# Usage: Type 'macmount' to connect, 'macunmount' to disconnect
function macmount() {
    # 1. Create directory if missing
    mkdir -p ~/macFlow

    # 2. Unmount gently if already mounted (cleans up stale connections)
    fusermount3 -u ~/macFlow 2>/dev/null

    # 3. Mount using local hostname (Bonjour)
    # Replace 'matt' and 'Matts-Mac.local' with your specific details
    echo "Connecting to macOS..."
    sshfs matt@Matts-Mac.local:/Users/matt/macFlow ~/macFlow -o allow_other,reconnect,uid=$(id -u),gid=$(id -g)

    # 4. Verify
    if [ $? -eq 0 ]; then
        echo "✅ Success: The macOS folder is mounted at ~/macFlow"
    else
        echo "❌ Error: Could not connect to macOS Host."
    fi
}

function macunmount() {
    fusermount3 -u ~/macFlow
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

*Note: Later, when you settle on a compositor (Sway/Hyprland), you can simply add `exec macmount` to its startup config to automate this.*
