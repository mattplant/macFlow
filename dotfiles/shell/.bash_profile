# ~/.bash_profile
# MacFlow Configuration

# ENVIRONMENT VARIABLES
export LANG='en_US.UTF-8'
export EDITOR='code --wait'

# Only add ~/.local/bin (Standard XDG location)
export PATH="$HOME/.local/bin:$PATH"

# SOURCE BASHRC
[[ -f ~/.bashrc ]] && . ~/.bashrc

# CONTEXT-AWARE WELCOME MESSAGE
# Define colors (Green)
G='\033[1;32m'
N='\033[0m'

# Check Context
if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    # --- SCENARIO: SSH SESSION ---
    echo ""
    echo -e "${G}:: macFlow Remote Session ::${N}"
    echo "--------------------------------"
    echo -e "Connected via SSH."
    echo ""

elif [[ -z "$WAYLAND_DISPLAY" && -z "$DISPLAY" ]]; then
    # --- SCENARIO: PHYSICAL TTY (The Black Screen) ---
    echo ""
    echo -e "${G}:: Welcome to macFlow ::${N}"
    echo "--------------------------------"
    echo -e "To launch the desktop, type: ${G}desktop${N}"
    echo ""
    echo "Quick Tips:"
    echo " * Input Capture: Ctrl + Option"
    echo " * Cheatsheet:    Cmd + /"
    echo ""
fi

# --- macFlow: SSHFS Mount Utility ---
# Usage: 'macmount' to connect, 'macunmount' to disconnect, 'macstatus' to check.
#
# While unmounted the mount point is kept read-only (0500). Without that guard
# ~/macFlow-HOST is just an ordinary directory: writes succeed, look completely
# normal, and never reach the Mac. fusermount needs write access to mount, so
# macmount opens it to 0700 only long enough to mount and macunmount re-arms it.

MACFLOW_MOUNT="$HOME/macFlow-HOST"
MACFLOW_REMOTE="macFlow-SHARE"   # relative to your Mac's home folder

_macflow_mounted() {
    if command -v mountpoint >/dev/null 2>&1; then
        mountpoint -q "$MACFLOW_MOUNT"
    else
        grep -qs " ${MACFLOW_MOUNT} fuse.sshfs " /proc/mounts
    fi
}

macstatus() {
    if _macflow_mounted; then
        echo "✅ mounted: host:$MACFLOW_REMOTE -> $MACFLOW_MOUNT"
    else
        echo "❌ not mounted — $MACFLOW_MOUNT is local to this VM"
    fi
}

macmount() {
    if _macflow_mounted; then
        echo "⚡ Already mounted at $MACFLOW_MOUNT"
        return 0
    fi

    mkdir -p "$MACFLOW_MOUNT" 2>/dev/null

    # Anything sitting here while unmounted was written locally and is NOT on
    # your Mac. Say so plainly before the mount hides it.
    local stray
    stray="$(ls -A "$MACFLOW_MOUNT" 2>/dev/null)"
    if [ -n "$stray" ]; then
        echo "⚠️  $MACFLOW_MOUNT is not empty while unmounted."
        echo "    These are local to this VM, NOT on your Mac:"
        echo "$stray" | sed 's/^/      /'
        echo "    They stay on disk, but are hidden while the mount is active."
    fi

    # Clear a wedged mount, then open the directory just enough to mount.
    fusermount3 -u "$MACFLOW_MOUNT" 2>/dev/null
    chmod 700 "$MACFLOW_MOUNT" 2>/dev/null

    echo "Connecting to macOS host..."
    if ! sshfs "host:$MACFLOW_REMOTE" "$MACFLOW_MOUNT" \
            -o allow_other,reconnect,uid="$(id -u)",gid="$(id -g)"; then
        chmod 500 "$MACFLOW_MOUNT" 2>/dev/null   # re-arm the guard
        echo "❌ Could not connect to your Mac."
        echo "   Check the network, then try: ssh host true"
        return 1
    fi

    # sshfs can exit 0 without leaving a usable mount, so confirm before
    # claiming success -- that false positive is what makes writes vanish.
    if ! _macflow_mounted; then
        chmod 500 "$MACFLOW_MOUNT" 2>/dev/null
        echo "❌ sshfs reported success but nothing is mounted."
        return 1
    fi

    echo "✅ Mounted your Mac's $MACFLOW_REMOTE at $MACFLOW_MOUNT"
}

macunmount() {
    if ! _macflow_mounted; then
        chmod 500 "$MACFLOW_MOUNT" 2>/dev/null   # arm it even if already down
        echo "Not mounted."
        return 0
    fi

    if fusermount3 -u "$MACFLOW_MOUNT"; then
        chmod 500 "$MACFLOW_MOUNT" 2>/dev/null   # re-arm the guard
        echo "Disconnected from macOS."
    else
        echo "❌ Unmount failed — something may still have files open."
        echo "   Check with: fuser -vm $MACFLOW_MOUNT"
        return 1
    fi
}
