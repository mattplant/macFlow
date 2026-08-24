# macFlow: Integration

For seamless development flow, we need a shared workspace between macOS and the Linux VM.

- **Files:**
  - We use **SSHFS** (SSH Filesystem) to reliably share files.
    - Unlike virtualization "Shared Folders," SSHFS correctly handles file permissions and file-watching events (crucial for Git and hot-reloading web servers).
- **Clipboard:** Copy/Paste is handled via **SPICE** (Desktop Mode) or **SSH** (Headless Mode).
- **Identity:** Git credentials are passed via **SSH Agent Forwarding**

This integration requires connectivity in two directions. They are separate, and each
needs its own key — being authorized in one direction does not authorize the other.

| | Direction | Purpose | Set up by |
| :-- | :-------- | :------ | :-------- |
| **Control Plane** | macOS → Linux | SSH into the VM, VS Code Remote | **You**, Part 2 below |
| **Data Plane** | Linux → macOS | The VM mounting your files over SSHFS | **`connect_mac.sh`**, run inside the VM |

So Part 2 is manual and Part 3 is automated. If you have already run
[`connect_mac.sh`](../../scripts/connect_mac.sh), the guest side is done and you only
need Part 1 and Part 2 here.

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

*Note:* The guest side is handled automatically. [`ansible/setup.yml`](../../ansible/setup.yml)
installs `sshfs`, enables `user_allow_other` in `/etc/fuse.conf`, and creates the
`~/macFlow-HOST` mount point. [`scripts/connect_mac.sh`](../../scripts/connect_mac.sh)
then writes the `host` SSH alias and authorizes this VM on your Mac.

### Usage

From inside the Linux VM (or via SSH), use these shell functions:

- Connect: `macmount`
  - Mounts macOS `~/macFlow-SHARE` to Linux `~/macFlow-HOST`.
- Disconnect: `macunmount`
  - Unmounts the shared folder from the Linux VM.
- Check: `macstatus`
  - Reports whether the share is currently mounted.

> *Why the two names differ:* `macFlow-SHARE` is the folder you share **out** from
> macOS; `macFlow-HOST` is where **the host's** files appear inside the VM. Same
> directory, named for whichever side you are standing on.

### The mount point is read-only when unmounted

`~/macFlow-HOST` is deliberately kept at mode `0500` while nothing is mounted, and
`macmount` opens it only long enough to mount.

Without that, an unmounted `~/macFlow-HOST` is an ordinary writable directory:
files you save there succeed, look completely normal, and never reach your Mac —
then vanish from view the next time you mount over them. If you see
`Permission denied` writing to `~/macFlow-HOST`, that is the guard telling you the
share is not mounted. Run `macmount`.
