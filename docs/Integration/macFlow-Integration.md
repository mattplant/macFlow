# macFlow: Integration

For seamless development flow, we need a shared workspace between macOS and the Linux VM.

- **Files:**
  - We use **SSHFS** (SSH Filesystem) to reliably share files.
    - Unlike virtualization "Shared Folders," SSHFS correctly handles file permissions and file-watching events (crucial for Git and hot-reloading web servers).
- **Clipboard:** Copy/Paste is handled via **SPICE** (Desktop Mode) or **SSH** (Headless Mode).
- **Identity:** Git credentials are passed via **SSH Agent Forwarding**

This integration requires connectivity in two directions:

1. **Control Plane (macOS -> Linux):** Using SSH to access the VM terminal.
2. **Data Plane (Linux -> macOS):** The VM mounting macOS files via SSHFS.

## Part 1: Host Configuration (macOS)

### Enable Remote Login

We must allow the VM to "log in" to your Mac to mount the shared filesystem.

- Open **System Settings** on macOS.
- Go to **General** > **Sharing**.
- Note the **Local hostname** (e.g. `myMac.local`). Feel free to update it now.
- Toggle **Remote Login** to **ON**.
- Click the **`i`** (Info) button:
  - Make sure `Allow disk access for remote users` is left **OFF** for security (unless you specifically need to mount protected system folders).
  - **Allow access for:** Add your macOS user and remove `Administrator`.
- *Security Note:* Turn on firewall, hide macOS from network discovery, etc. as desired for security.

### Create the Shared Folder

Create the directory on your Mac that will serve as the shared file workspace. Avoid system-protected folders like `Desktop` or `Documents`.

```bash
mkdir ~/macFlow-SHARE
```

## Part 2: Control Plane (Accessing the VM)

Set up effortless SSH access from macOS to the Linux VM.

### Setup SSH Keypair (macOS)

If you don't already have an SSH keypair for your macOS user, create one now:

```bash
# On your macOS Terminal, generate SSH Keypair
# -t ed25519: Uses the modern, fast Edwards-curve algorithm
# This creates two files in ~/.ssh/:
#   - id_ed25519 (Private Key - KEEP SECRET)
#   - id_ed25519.pub (Public Key - Shared with Host)
ssh-keygen -t ed25519 -C "macflow-host"
# Press Enter to Accept the defaults.
# Leave passphrase empty if you want fully passwordless login.
```

### Configure SSH Config

Add this block to your macOS SSH config (`~/.ssh/config`) to create a shortcut and enable key forwarding:

```bash
# Host macflow: Shortcut to connect to your Linux VM
# - HostName: The LAN hostname or IP address of your Linux VM
# - User: The username you created during Arch Linux installation
# - ForwardAgent: allows your key ring to be passed to the VM
# - AddKeysToAgent: adds keys to the ssh-agent automatically when used
# - UseKeychain: saves the keys in the macOS Keychain for easy reuse
Host macflow
    HostName macflow.local
    User macflow
    ForwardAgent yes
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519
```

#### Authorize the Key

Copy your Mac's public key to the Linux VM so you can log in without a password.

```bash
ssh-copy-id macflow
# (You will type your Linux VM password one last time)
```

### Setup and Verify Identity Bridge (SSH Agent Forwarding)

This allows the Linux VM to use the Git credentials stored on your Mac, so you don't have to manage new keys inside the VM.

```bash
# Make your ssh key that you use for GitHub/GitLab available to the ssh-agent
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# SSH into the Linux VM using the new shortcut
ssh macflow

# Check the Agent inside Linux: Run this command inside the VM:
ssh-add -l
# Success if you see your key fingerprint
# Failure if it responds: "The agent has no identities."
```

## Part 3: Data Plane (Shared Filesystem)

We use SSHFS to mount the macOS folder (~/macFlow-SHARE) inside the Linux VM.

### Guest Configuration

*Note:* This is handled automatically by the configArch.sh script during installation.

### Usage

From inside the Linux VM (or via SSH), use the aliases:

- Connect: `macmount`
  - Mounts macOS ~/macFlow-SHARE to Linux ~/macFlow-HOST.
- Disconnect: `macunmount`
  - Unmounts the shared folder from the Linux VM.
