# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ---------------------------------------------------------
# 1. BASIC SETTINGS
# ---------------------------------------------------------
# Append to the history file, don't overwrite it
shopt -s histappend
HISTSIZE=5000
HISTFILESIZE=10000
# Don't put duplicate lines or lines starting with space in the history
HISTCONTROL=ignoreboth

# Check the window size after each command
shopt -s checkwinsize

# Enable color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# ---------------------------------------------------------
# 2. PROMPT (Terminal / Hacker Style)
# ---------------------------------------------------------
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
# PS1='[\u@\h \W]\$ '
. /etc/profile.d/custom-bash-options.sh


# ---------------------------------------------------------
# 3. MACFLOW ALIASES & NAVIGATION
# ---------------------------------------------------------

# Sh
alias sbp='source ~/.bash_profile' # Source bash_profile
alias sbrc='source ~/.bashrc' # Source bashrc
alias a='alias'

# File & Directory Navigation
alias ll='ls -alFh'      # Long, all, classified, human-readable sizes
alias la='ls -A'         # List all except . and ..
alias l='ls -CF'         # Column list, classified
alias ..='cd ..'
alias ...='cd ../..'

# Git Shortcuts
alias gs='git status'
alias ga='git add -A'    # Add all changes
alias gc='git commit -v' # Verbose commit (opens EDITOR)
alias gp='git push'
alias gco='git checkout'
alias gcm='git checkout main || git checkout master'

# VS Code (Force Wayland/Ozone backend)
alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'

# Hyprland / System
alias displayInfo='hyprctl monitors'
alias displayReload='hyprctl reload'
alias displayWaybarReload='killall waybar && waybar & disown'

# Resolution Presets (UTM)
alias displayResolutionMBA='wlr-randr --output Virtual-1 --custom-mode 2880x1864 --scale 2'
alias displayResolution4K='wlr-randr --output Virtual-1 --custom-mode 3840x2160 --scale 2'
alias displayResolution2560x1440='wlr-randr --output Virtual-1 --custom-mode 2560x1440 --scale 2'

# ---------------------------------------------------------
# 4. PATH & ENVIRONMENT
# ---------------------------------------------------------
export PATH=$PATH:$HOME/.local/bin

# Set VS Code as default editor
# We use --wait so git commands pause until you close the file in VS Code
export EDITOR='code --wait'
