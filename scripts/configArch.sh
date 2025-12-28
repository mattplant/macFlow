#!/bin/bash
# configArch.sh
# Sets up Package Management (Yay), Drivers, Kernel Modules, SSH, and Shared Filesystem.

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

# mesa: 3D Graphics Acceleration (virtio-gpu)
# linux-headers: For module compiling
# qemu-guest-agent: Host communication
# openssh: Remote access
# avahi, nss-mdns: Hostname resolution (.local)
# sshfs: For mounting macOS folders
PKGS=(
    mesa
    linux-headers
    qemu-guest-agent
    openssh
    avahi
    nss-mdns
    sshfs
)

yay -S --needed --noconfirm "${PKGS[@]}"

# --- Configure Hostname Resolution (.local) ---
log "Step 4: Configuring Avahi (mDNS)..."

# Enable Avahi Daemon (Bonjour) for .local hostname resolution
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
    ssh-keygen -t ed25519 -C "$USER" -f "$KEY_FILE" -N ""
    success "SSH Key generated."
fi

# --- Install GNU Stow ---
log "Step 7: Installing GNU Stow"

yay -S --needed --noconfirm stow

# --- Deploy Configurations (Dotfiles) ---
log "Step 8: Linking Dotfiles..."

REPO_DIR="$HOME/macFlow"
DOTFILES_DIR="$REPO_DIR/dotfiles"

# Ensure repo exists
if [ ! -d "$DOTFILES_DIR" ]; then
    warn "Dotfiles directory not found at $DOTFILES_DIR!"
    warn "Please clone the repo first: git clone https://github.com/mattplant/macFlow.git $HOME/macFlow"
    exit 1
fi

cd "$DOTFILES_DIR"

# Ensure target config directory exists
mkdir -p ~/.config

# Backup .bashrc and .bash_profile if they exist and are NOT symlinks so Stow can deploy them.
for file in ".bashrc" ".bash_profile" ".bash_login"; do
    if [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
        log "Backing up existing $file to $file.bak to prevent conflicts..."
        mv "$HOME/$file" "$HOME/$file.bak"
    fi
done

# Link Packages via Stow
# We use -R (Restow) to refresh links if they exist
stow -R -t ~ shell     # .bash_profile, .zshrc
stow -R -t ~ scripts   # ~/bin/ utilities
stow -R -t ~ foot      # Foot Terminal config
stow -R -t ~ hypr      # Hyprland, Waybar, Wofi, Dunst configs

# Reload shell profile to apply path changes immediately for this script
source ~/.bash_profile 2>/dev/null || true

success "Dotfiles linked."

# --- Configure Shared Filesystem ---
log "Step 9: Configuring Shared Filesystem..."

echo "------------------------------------------------"
echo "To enable file sharing, we need to connect to your Mac."
echo "Ensure 'Remote Login' is ON in macOS System Settings > General > Sharing."
echo "------------------------------------------------"
read -p "Do you want to configure macOS file sharing now? (y/n): " setup_share

if [[ "$setup_share" =~ ^[Yy]$ ]]; then
    # 1. Gather Info
    read -p "Enter macOS Hostname (e.g. MyMac.local): " mac_host
    read -p "Enter macOS Username: " mac_user

    # 2. Configure FUSE (Allow non-root users to access mounts)
    if grep -q "^#user_allow_other" /etc/fuse.conf; then
        log "Enabling 'user_allow_other' in /etc/fuse.conf..."
        sudo sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf
    fi

    # 3. Create SSH Config
    SSH_CONFIG="$HOME/.ssh/config"
    mkdir -p ~/.ssh

    if grep -q "Host host" "$SSH_CONFIG" 2>/dev/null; then
        warn "Host 'host' already exists in ~/.ssh/config. Skipping config write."
    else
        log "Writing host alias to ~/.ssh/config..."
        cat <<EOF >> "$SSH_CONFIG"

Host host
    HostName $mac_host
    User $mac_user
    IdentityFile ~/.ssh/id_ed25519
EOF
        chmod 600 "$SSH_CONFIG"
    fi

    # 4. Create Mount Point
    mkdir -p "$HOME/macFlow-HOST"

    # 5. Exchange Keys
    log "Copying SSH key to macOS..."
    echo -e "${YELLOW}NOTE: You will be asked for your MAC PASSWORD to authorize the key.${NC}"
    ssh-copy-id host

    if [ $? -eq 0 ]; then
        success "SSH Key copied successfully."
        echo -e "You can now mount your files using the command: ${GREEN}macmount${NC}"
    else
        error "SSH Key copy failed. Verify your Mac hostname/username and try again later."
    fi
else
    log "Skipping Shared Filesystem setup."
fi

# --- Done ---
echo ""
success "macFlow Arch Linux configuration complete!"
echo "------------------------------------------------"
echo "Next Steps:"
echo "1. Reboot your VM."
echo "2. Login either thru the console or via SSH with: ssh $USER@$(uname -n).local"
echo "3. Use 'macmount' to connect your shared folder."
echo "------------------------------------------------"
