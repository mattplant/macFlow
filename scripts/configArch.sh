#!/bin/bash
# configArch.sh
# Sets up Package Management (Yay), Drivers, Kernel Modules, and SSH.

set -e  # Exit on error

# --- Helpers ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

log() { echo -e "${BLUE}[macFlow]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# --- 1. Package Management (Yay) ---
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

# --- 2. Install Drivers & Services ---
log "Step 2: Installing Drivers (Mesa, Guest Agent, SSH)..."

# mesa: 3D Graphics
# linux-headers: For module compiling
# qemu-guest-agent: Host communication (re-adding this since we removed it)
# openssh: For remote access
yay -S --needed --noconfirm mesa linux-headers qemu-guest-agent openssh

# --- 3. Configure Kernel (mkinitcpio) ---
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

# --- 4. Enable Services ---
log "Step 4: Enabling Services..."

# QEMU Guest Agent
sudo systemctl start qemu-guest-agent

# Enable SSH
sudo systemctl enable --now sshd

# --- 5. Install GNU Stows ---
log "Step 5: Installing GNU Stow"

yay -S --needed --noconfirm stow

# --- Done ---
echo ""
success "macFlow Arch config complete!"
