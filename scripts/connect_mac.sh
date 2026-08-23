#!/bin/bash
# connect_mac.sh
# First-run handshake: gives this VM its own identity and links it to your Mac.
#
# Everything here needs a human (your Mac's hostname, your password), which is
# why it is not part of ansible/setup.yml. Run it once per VM.
#
# Order matters: this script collects and *verifies* everything it needs before
# it changes anything on the system. An earlier version regenerated SSH host
# keys first, so answering a prompt wrong left the VM with a new identity and
# nothing else done.

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

SSH_CONFIG="$HOME/.ssh/config"

# --- Pre-flight Check ---
if [ "$EUID" -eq 0 ]; then
  error "Please run this script as your normal user, not as root (sudo)."
  exit 1
fi

# Read a value out of the existing "Host host" block, so re-runs can offer
# what you entered last time instead of asking blind.
existing_ssh_value() {
    local key="$1"
    [ -f "$SSH_CONFIG" ] || return 0
    awk -v key="$key" '
        /^[[:space:]]*Host[[:space:]]/ { inblock = ($2 == "host"); next }
        inblock && tolower($1) == tolower(key) { print $2; exit }
    ' "$SSH_CONFIG"
}

# Best guess at the Mac's address, in descending order of reliability.
detect_mac_host() {
    # 1. Whatever a previous run recorded.
    local prev
    prev="$(existing_ssh_value HostName)"
    if [ -n "$prev" ]; then echo "$prev"; return; fi

    # 2. If you are running this over SSH, the client IS your Mac.
    if [ -n "$SSH_CONNECTION" ]; then
        echo "$SSH_CONNECTION" | awk '{print $1}'
        return
    fi

    # 3. Ask the network who is advertising SSH over mDNS. Time-boxed, because
    #    avahi will otherwise keep browsing forever.
    if command -v avahi-browse >/dev/null 2>&1; then
        timeout 5 avahi-browse -d local _ssh._tcp --terminate -p 2>/dev/null \
            | awk -F';' '/^=/ {print $7}' | sort -u | head -1
    fi
}

# Returns 0 if we can open a TCP connection to port 22 there.
can_reach_ssh() {
    timeout 8 bash -c "cat < /dev/null > /dev/tcp/$1/22" 2>/dev/null
}

echo "------------------------------------------------"
echo "macFlow: connect this VM to your Mac"
echo "------------------------------------------------"
echo "Before continuing, on macOS:"
echo "  1. System Settings > General > Sharing > Remote Login = ON"
echo "  2. Create the shared folder:  mkdir ~/macFlow-SHARE"
echo ""
echo "Tip: your Mac's hostname is NOT its friendly name ('Matt's MacBook Air')."
echo "     Find it on macOS with:  scutil --get LocalHostName"
echo "     then add '.local'. An IP address works too."
echo "------------------------------------------------"

# --- 1. Collect and Verify (no system changes yet) ---
log "Step 1: Collecting your Mac's details..."

default_host="$(detect_mac_host || true)"
default_user="$(existing_ssh_value User || true)"

while true; do
    if [ -n "$default_host" ]; then
        read -r -p "macOS hostname or IP [$default_host]: " mac_host
        mac_host="${mac_host:-$default_host}"
    else
        read -r -p "macOS hostname or IP: " mac_host
    fi

    if [ -z "$mac_host" ]; then
        warn "A hostname or IP is required."
        continue
    fi

    log "Checking whether $mac_host is reachable on port 22..."
    if can_reach_ssh "$mac_host"; then
        success "$mac_host is reachable."
        break
    fi

    warn "Could not reach $mac_host on port 22."
    warn "Check that Remote Login is ON, and that the name resolves from here."
    read -r -p "Try a different address? (y/n): " retry
    if [[ ! "$retry" =~ ^[Yy]$ ]]; then
        error "Aborting without changing anything."
        exit 1
    fi
    default_host=""
done

while true; do
    if [ -n "$default_user" ]; then
        read -r -p "macOS username [$default_user]: " mac_user
        mac_user="${mac_user:-$default_user}"
    else
        read -r -p "macOS username: " mac_user
    fi
    [ -n "$mac_user" ] && break
    warn "A username is required."
done

# --- 2. Confirm the Plan ---
echo ""
echo "------------------------------------------------"
echo "About to configure:"
echo "  Mac address : $mac_host"
echo "  Mac user    : $mac_user"
echo "------------------------------------------------"
read -r -p "Proceed? (y/n): " proceed
if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
    log "Aborted. Nothing was changed."
    exit 0
fi

# --- 3. Regenerate SSH Host Keys ---
# A VM built from a shared base image inherits that image's host keys, so every
# clone would present the same identity. Give this machine its own.
log "Step 2: SSH host keys..."

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

# --- 4. Write the SSH Host Alias ---
# Lets the macmount helper (and you) refer to the Mac simply as "host".
log "Step 3: Writing the 'host' alias to ~/.ssh/config..."

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

write_alias=yes
if grep -qE '^[[:space:]]*Host[[:space:]]+host[[:space:]]*$' "$SSH_CONFIG" 2>/dev/null; then
    echo ""
    warn "A 'Host host' entry already exists:"
    awk '
        /^[[:space:]]*Host[[:space:]]/ { inblock = ($2 == "host") }
        inblock { print "    | " $0 }
    ' "$SSH_CONFIG"
    echo ""
    read -r -p "Replace it with the values above? (y/n): " replace
    if [[ "$replace" =~ ^[Yy]$ ]]; then
        cp "$SSH_CONFIG" "$SSH_CONFIG.bak"
        # Drop the old block: our marker comment, plus everything from
        # "Host host" until the next "Host " line (or end of file). Dropping
        # the comment matters -- it sits *above* the block, so leaving it
        # behind means a stray comment accumulates on every re-run.
        awk '
            /^# macFlow: your Mac/ { next }
            /^[[:space:]]*Host[[:space:]]/ { skip = ($2 == "host") }
            !skip { print }
        ' "$SSH_CONFIG.bak" > "$SSH_CONFIG"
        log "Previous entry backed up to $(basename "$SSH_CONFIG").bak"
    else
        write_alias=no
        log "Keeping the existing entry."
    fi
fi

if [ "$write_alias" = yes ]; then
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

# --- 5. Authorize This VM On Your Mac ---
log "Step 4: Copying this VM's public key to your Mac..."
echo -e "${YELLOW}NOTE: You will be asked for your MAC password to authorize the key.${NC}"

if ssh-copy-id host; then
    success "SSH key authorized."
else
    error "Key copy failed. Check the username and your Mac password."
    exit 1
fi

# --- 6. Verify ---
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
