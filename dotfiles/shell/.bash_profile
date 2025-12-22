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
