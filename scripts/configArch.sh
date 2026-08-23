#!/bin/bash
# configArch.sh
# Manual-install entry point for configuring an Arch Linux guest.
#
# The actual configuration lives in ansible/setup.yml, which is also what the
# Packer build applies via its ansible-local provisioner. This script just
# installs Ansible and runs that playbook against the local machine, so both
# install paths execute identical logic.
#
# Interactive host setup (linking this VM to your Mac) is a separate step:
# see scripts/connect_mac.sh.

set -e  # Exit on error

# --- Helpers ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${BLUE}[macFlow]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Pre-flight Check ---
if [ "$EUID" -eq 0 ]; then
  error "Please run this script as your normal user, not as root (sudo)."
  exit 1
fi

# Resolve the repo root from this script's own location, so the script works
# regardless of where it is called from.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAYBOOK="$REPO_DIR/ansible/setup.yml"

if [ ! -f "$PLAYBOOK" ]; then
    error "Playbook not found at $PLAYBOOK"
    error "Clone the full repo: git clone https://github.com/mattplant/macFlow.git ~/macFlow"
    exit 1
fi

# --- Install Ansible ---
log "Installing Ansible..."
sudo pacman -S --needed --noconfirm ansible

# --- Apply the Playbook ---
log "Applying $PLAYBOOK to this machine..."
echo "You will be prompted for your sudo password."

# -i localhost,   : one-host inventory (the trailing comma makes it a list)
# -c local        : run commands directly, no SSH
# --ask-become-pass: prompt once for the sudo password used to escalate
ansible-playbook \
    --inventory localhost, \
    --connection local \
    --extra-vars "macflow_user=$USER" \
    --ask-become-pass \
    "$PLAYBOOK"

# --- Done ---
echo ""
success "macFlow Arch Linux configuration complete!"
echo "------------------------------------------------"
echo "Next Steps:"
echo "1. Reboot your VM:          sudo reboot"
echo "2. Link this VM to your Mac: ~/macFlow/scripts/connect_mac.sh"
echo "3. Desktop Mode (optional):  ~/macFlow/scripts/installHyprland.sh"
echo "------------------------------------------------"
