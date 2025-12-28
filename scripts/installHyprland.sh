#!/bin/bash
# installHyprland.sh
# Installs Hyprland, UI tools, Terminal, Host integration, and links dotfiles.

set -e  # Exit on error

# --- Helpers ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

log() { echo -e "${BLUE}[macFlow]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# --- 1. Install Hyprland & Ecosystem ---
log "Step 1: Installing Hyprland and Tools..."

PKGS=(
    # Core Desktop
    hyprland xorg-xwayland qt5-wayland qt6-wayland polkit-gnome
    # UI Elements
    waybar dunst wofi hyprpaper pipewire-jack
    # Terminal & Fonts
    foot ttf-jetbrains-mono-nerd ttf-dejavu
    # Host Integration (Clipboard & X11)
    xclip clipnotify
    # Theming & Display Tools
    qt5ct qt6ct nwg-look gnome-themes-extra wlr-randr
)

# Use yay to handle everything (official + AUR)
yay -S --needed --noconfirm "${PKGS[@]}"
success "Desktop packages installed."

# --- 2. Fix Seat Permissions (Crash Prevention) ---
log "Step 2: Configuring Seat Permissions (seatd)..."
# This fixes the "No backend was able to open a seat" error

# Install seatd if missing
yay -S --needed --noconfirm seatd

# Enable the service
sudo systemctl enable --now seatd

# Add current user to 'seat' group
if groups "$USER" | grep &>/dev/null '\bseat\b'; then
    success "User '$USER' is already in 'seat' group."
else
    log "Adding user '$USER' to 'seat' group..."
    sudo usermod -aG seat "$USER"
    success "User added to seat group."
fi

# --- 3. Final Instructions ---
echo ""
success "Hyprland Installation Complete!"
echo "------------------------------------------------"
echo "CRITICAL NEXT STEPS:"
echo "1. Reboot your VM now. (Required for 'seat' group changes to take effect)."
echo "   sudo reboot"
echo ""
echo "2. After reboot, log in and type:"
echo "   desktop"
echo ""
echo "OPTIONAL SETUP:"
echo "- To set Dark Mode: Run 'nwg-look' and select Adwaita-dark."
echo "- To adjust resolution: Use 'wlr-randr' or edit ~/.config/hypr/hyprland.conf"
echo "------------------------------------------------"
