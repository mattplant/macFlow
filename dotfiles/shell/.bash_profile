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
# Usage: Type 'macmount' to connect, 'macunmount' to disconnect

function macmount() {
    local MOUNT_POINT="$HOME/macFlow-HOST"
    local REMOTE_PATH="macFlow-SHARE" # Relative to your Mac Home folder

    # 1. Safety Check: Is it already mounted?
    if mount | grep -q "$MOUNT_POINT"; then
        echo "⚡ macOS is already mounted at $MOUNT_POINT"
        return 0
    fi

    # 2. Ensure mount point exists
    if [ ! -d "$MOUNT_POINT" ]; then
        echo "Creating mount point: $MOUNT_POINT"
        mkdir -p "$MOUNT_POINT"
    fi

    # 3. Cleanup stale connections (force unmount if stuck)
    if [ -e "$MOUNT_POINT" ]; then
        fusermount3 -u "$MOUNT_POINT" 2>/dev/null
    fi

    # 4. Mount macOS Shared Folder
    echo "Connecting to macOS Host..."
    # - Syntax: sshfs [alias]:[remote_path] [local_path] [options]
    #   - host: The alias we configured in ~/.ssh/config above
    #   - remote_path: /Users/matt/macFlow-SHARE
    #   - local_path: ~/macFlow-HOST
    #   - options:
    #     - 'allow_other': allows other users (root) to see files
    #     - 'reconnect': automatically restores connection after sleep/resume
    #     - `uid=$(id -u),gid=$(id -g)`: ensures the files appear as owned by your linux user
    sshfs "host:$REMOTE_PATH" "$MOUNT_POINT" -o allow_other,reconnect,uid=$(id -u),gid=$(id -g)

    # 5. Verify result
    if [ $? -eq 0 ]; then
        echo "✅ Success: Shared folder mounted."
    else
        echo "❌ Error: Could not connect to Host. Check network or SSH config."
    fi
}

function macunmount() {
    fusermount3 -u ~/macFlow-HOST
    echo "Disconnected from macOS."
}
