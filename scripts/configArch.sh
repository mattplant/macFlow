#!/bin/bash
# configArch.sh
# Sets up Package Management (Yay), Drivers, Kernel Modules, and SSH.

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

# --- Package Management (Yay) ---
log "Step 1: Setting up Package Management..."

# Install Prerequisites
sudo pacman -S --needed --noconfirm base-devel git

# Install Yay (if not found)
if ! command -v yay &> /dev/null; then
    log "Building 'yay' from AUR..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay
    success "Yay installed."
else
    success "Yay is already installed."
fi

# --- Install Drivers & Services ---
log "Step 2: Installing Drivers & Services..."

# mesa: 3D Graphics
# linux-headers: For module compiling
# qemu-guest-agent: Host communication
# openssh: Remote access
# avahi, nss-mdns: Hostname resolution (.local)
PKGS=(
    mesa
    linux-headers
    qemu-guest-agent
    openssh
    avahi
    nss-mdns
)

yay -S --needed --noconfirm "${PKGS[@]}"

# --- Configure Kernel (mkinitcpio) ---
log "Step 3: Configuring Kernel Modules (VirtIO GPU)..."

CONFIG_FILE="/etc/mkinitcpio.conf"
MODULES="virtio virtio_pci virtio_blk virtio_net virtio_gpu"

# Check if modules are already present to avoid duplication
if grep -q "virtio_gpu" "$CONFIG_FILE"; then
    success "Kernel modules already configured."
else
    log "Injecting virtio drivers into mkinitcpio.conf..."
    # Backup original file
    sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    # Use sed to insert modules inside the MODULES=() parentheses
    # This finds 'MODULES=(...)' and appends our modules inside the closing ')'
    sudo sed -i "s/MODULES=(\(.*\))/MODULES=(\1 $MODULES)/" "$CONFIG_FILE"

    # Regenerate initramfs
    log "Regenerating kernel images (this may take a moment)..."
    sudo mkinitcpio -P
    success "Kernel configured."
fi

# --- Configure Hostname Resolution (.local) ---
log "Step 4: Configuring Avahi (mDNS)..."

# Enable Avahi Daemon
sudo systemctl enable --now avahi-daemon

# Edit nsswitch.conf to allow .local resolution
# We need 'mdns_minimal [NOTFOUND=return]' to appear before 'resolve' or 'dns'
NSS_FILE="/etc/nsswitch.conf"

if grep -q "mdns_minimal" "$NSS_FILE"; then
    success "nsswitch.conf already configured for mDNS."
else
    log "Patching /etc/nsswitch.conf..."
    # Backup original file
    sudo cp "$NSS_FILE" "${NSS_FILE}.bak"

    # This sed command looks for the "hosts:" line and replaces the text "resolve"
    # with "mdns_minimal [NOTFOUND=return] resolve" effectively inserting it before.
    # If "resolve" isn't there (older setups), it tries to insert before "dns".
    if grep -q "resolve" "$NSS_FILE"; then
         sudo sed -i 's/resolve/mdns_minimal [NOTFOUND=return] resolve/' "$NSS_FILE"
    else
         sudo sed -i 's/dns/mdns_minimal [NOTFOUND=return] dns/' "$NSS_FILE"
    fi
    success "Hostname resolution configured."
fi

# --- Enable Services ---
log "Step 5: Enabling Services..."

# QEMU Guest Agent
sudo systemctl start qemu-guest-agent

# Enable SSH
sudo systemctl enable --now sshd

# --- Generate User SSH Key ---
log "Step 6: Generating User SSH Key..."

KEY_FILE="$HOME/.ssh/id_ed25519"

if [ -f "$KEY_FILE" ]; then
    success "SSH Key already exists. Skipping generation."
else
    # -N "" creates it with NO passphrase (fully automated).
    # Remove -N "" if you want to be prompted for a password.
    ssh-keygen -t ed25519 -C "$USER" -f "$KEY_FILE" -N ""
    success "SSH Key generated."
fi

# --- Install GNU Stows ---
log "Step 7: Installing GNU Stow"

yay -S --needed --noconfirm stow

# --- Done ---
echo ""
success "macFlow Arch config complete!"
echo "------------------------------------------------"
echo "Next Steps:"
echo "1. Reboot your VM."
echo "2. You should now be able to SSH via: ssh $USER@$(uname -n).local"
echo "------------------------------------------------"
