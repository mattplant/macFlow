#!/bin/bash
# connect_mac.sh
# First-run handshake: gives this VM its own identity and links it to your Mac.
#
# Everything here needs a human (your Mac's hostname, your password), which is
# why it is not part of ansible/setup.yml. Run it once per VM.

set -e  # Exit on error

# --- Helpers ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${BLUE}[macFlow]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Pre-flight Check ---
if [ "$EUID" -eq 0 ]; then
  error "Please run this script as your normal user, not as root (sudo)."
  exit 1
fi

echo "------------------------------------------------"
echo "macFlow: connect this VM to your Mac"
echo "------------------------------------------------"
echo "Before continuing, on macOS:"
echo "  1. System Settings > General > Sharing > Remote Login = ON"
echo "  2. Create the shared folder:  mkdir ~/macFlow-SHARE"
echo "------------------------------------------------"
read -r -p "Ready to continue? (y/n): " proceed
if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
    log "Aborted. Re-run this script when you are ready."
    exit 0
fi

# --- 1. Regenerate SSH Host Keys ---
# A VM built from a shared base image inherits that image's host keys, so every
# clone would present the same identity. Give this machine its own.
log "Step 1: Regenerating SSH host keys..."

read -r -p "Regenerate this VM's SSH host keys? Recommended on a fresh image. (y/n): " regen
if [[ "$regen" =~ ^[Yy]$ ]]; then
    sudo rm -f /etc/ssh/ssh_host_*
    sudo ssh-keygen -A
    sudo systemctl restart sshd
    success "Host keys regenerated."
    warn "Macs that connected to this VM before will report a changed host key."
else
    log "Keeping existing host keys."
fi

# --- 2. Gather Mac Details ---
log "Step 2: Collecting your Mac's details..."

read -r -p "Enter macOS hostname (e.g. MyMac.local): " mac_host
read -r -p "Enter macOS username: " mac_user

if [ -z "$mac_host" ] || [ -z "$mac_user" ]; then
    error "Hostname and username are both required."
    exit 1
fi

# --- 3. Write the SSH Host Alias ---
# Lets the macmount helper (and you) refer to the Mac simply as "host".
log "Step 3: Writing the 'host' alias to ~/.ssh/config..."

SSH_CONFIG="$HOME/.ssh/config"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if grep -q "^Host host$" "$SSH_CONFIG" 2>/dev/null; then
    warn "Host 'host' already exists in ~/.ssh/config. Leaving it unchanged."
    warn "Edit that file by hand if your Mac's hostname has changed."
else
    cat <<EOF >> "$SSH_CONFIG"

# macFlow: your Mac, as seen from this VM
Host host
    HostName $mac_host
    User $mac_user
    IdentityFile ~/.ssh/id_ed25519
EOF
    chmod 600 "$SSH_CONFIG"
    success "Alias written."
fi

# --- 4. Authorize This VM On Your Mac ---
log "Step 4: Copying this VM's public key to your Mac..."
echo -e "${YELLOW}NOTE: You will be asked for your MAC password to authorize the key.${NC}"

if ssh-copy-id host; then
    success "SSH key authorized."
else
    error "Key copy failed. Check the hostname, username, and that Remote Login is ON."
    exit 1
fi

# --- 5. Verify ---
log "Step 5: Verifying the shared folder..."

if ssh -o BatchMode=yes host "test -d ~/macFlow-SHARE"; then
    success "Found ~/macFlow-SHARE on your Mac."
else
    warn "Could not find ~/macFlow-SHARE on your Mac."
    warn "Create it there with: mkdir ~/macFlow-SHARE"
fi

# --- Done ---
echo ""
success "Handshake complete!"
echo "------------------------------------------------"
echo "Next Steps:"
echo "1. Mount your Mac's shared folder:  macmount"
echo "2. Disconnect it again with:        macunmount"
echo "3. Desktop Mode (optional):         ~/macFlow/scripts/installHyprland.sh"
echo "------------------------------------------------"
