#!/bin/bash
# macFlow Cheatsheet
# Displays keybindings in a floating terminal.

# -- Colors (Matrix Style) --
GREEN='\033[1;32m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

clear

echo -e "${GREEN}"
cat << "EOF"
                                        _____ _
                                       |  ___| |
                        _ __ ___   __ _| |__ | | _____      __
                       | '_ ` _ \ / _` |  __|| |/ _ \ \ /\ / /
                       | | | | | | (_| | |   | | (_) \ V  V /
                       |_| |_| |_|\__,_|_|   |_|\___/ \_/\_/
                                KEYBINDING REFERENCE
EOF

# Function to print a row
print_row() {
    printf "${GREEN}%-20s ${WHITE}%-20s ${GREEN}%-20s ${WHITE}%-20s${NC}\n" "$1" "$2" "$3" "$4"
}

# Function to print a section header
print_head() {
    echo -e "\n${GREEN}:: $1 ::${NC}"
}

print_head "WINDOW CONTROL"
print_row "Cmd + Q" "Close Window" "Cmd + F" "Fullscreen"
print_row "Cmd + Tab" "Next Window" "Cmd + Shft + Tab" "Previous Window"
print_row "Cmd + Arrow" "Move Focus" "Cmd + Shft + Arrow" "Move Window"

print_head "SYSTEM & APPS"
print_row "Cmd + Enter" "Terminal (Foot)" "Cmd + Space" "App Launcher"
print_row "Cmd + B" "Browser" "Cmd + E" "Editor"

print_head "WORKSPACES"
print_row "Cmd + 1-5" "Switch Workspace" "Cmd + Shft + 1-5" "Move Window to Workspace"
print_row "Cmd + Ctrl + Left" "Previous Workspace" "Cmd + Ctrl + Right" "Next Workspace"

print_head "HELP"
print_row "Cmd + /" "Show This Help" "" ""

print_head "UTM HOST CONTROLS"
print_row "Ctrl + Opt (LEFT)" "Capture Input Toggle" "" ""

echo -e "${NC}"
echo -e "${GREEN}Press any key to close...${NC}"

# Wait for input to close
read -n 1 -s