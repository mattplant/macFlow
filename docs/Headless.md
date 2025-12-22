# macFlow: "Headless" Integration with Linux VM

When in "Headless" mode (no GUI), we need to establish reliable integration points between the Host (macOS) and Guest (Linux VM).

- **Files:** Files are shared via **SSHFS**.
- **Clipboard:** Copy/Paste is handled via **SSH**
- **Identity:** Git credentials are passed via **SSH Agent Forwarding**

## The File Bridge (SSHFS)

We use **SSHFS** (SSH Filesystem) to reliably share files between the Host (macOS) and Guest (Linux VM).

For details, see [macFlow: File Integration](./Integration/Files.md).

## Clipboard Sync Over SSH

We can use SSH to reliably share the clipboard between the Host (macOS) and Guest (Linux VM) while in "Headless" mode (no GUI).

## The Identity Bridge (SSH Agent Forwarding)

We want to be able to use git inside the Linux VM, but have it use the SSH keys stored in your macOS Keychain for authentication.

### Setup Passwordless Access (SSH Keys) to the Linux VM

```bash
# On you macOS Terminal, generate SSH Keypair
# -t ed25519: Uses the modern, fast Edwards-curve algorithm
# This creates two files in ~/.ssh/:
#   - id_ed25519 (Private Key - KEEP SECRET)
#   - id_ed25519.pub (Public Key - Shared with Host)
ssh-keygen -t ed25519 -C "macflow-host"
# (Accept the default location/name so it is used automatically)
# (Leave passphrase empty for passwordless login)

# Copy the Public Key to the Linux VM
# This script logs into your Linux VM and adds your Public Key to the `~/.ssh/authorized_keys` file on the host.
ssh-copy-id macflow@macflow.local
# (Type your Linux VM password one last time to authorize the copy)

# Verify Copy/Paste Works
ssh macflow@macflow.local
# (You should be logged in immediately without a password.)
# Now test copy/paste:
# - Copy some text from elsewhere on macOS and paste it (Cmd+V) in the Terminal
# - Copy some text in the Terminal and paste it (Cmd+V) into a different app in your macOS
```

### Configure the Host (macOS)

We need to tell your Mac's SSH client to forward your identity when it connects to the Linux VM.

```bash
# Open your macOS SSH Config:
nano ~/.ssh/config
# Add this "macflow" ssh config block to configure the connection to the Linux VM
# - ForwardAgent: allows your key ring is passed to the VM
# - AddKeysToAgent: adds keys to the ssh-agent automatically when used
# - UseKeychain: saves the keys in the macOS Keychain for easy reuse
Host macflow
    HostName macflow.local
    User macflow
    ForwardAgent yes
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519

# Make your ssh key that you use for GitHub/GitLab available to the ssh-agent
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
# (Saving to the Apple keychain makes it available automatically on future logins)
```

### Verify the Identity Bridge

```bash
# SSH into the VM using the new shortcut
ssh macflow

# Check the Agent inside Linux: Run this command inside the VM:
ssh-add -l
# Success if you see your key fingerprint
# Failure if it responds: "The agent has no identities."

# Real world test with Git (Use your actual repo)
git clone git@github.com:git/git.git
