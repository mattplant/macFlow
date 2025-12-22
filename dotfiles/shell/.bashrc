# ~/.bashrc
# MacFlow Configuration

# If not interactive, exit (prevents errors in scripts)
[[ $- != *i* ]] && return

# HISTORY & OPTIONS
shopt -s histappend checkwinsize
HISTSIZE=5000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth

# COLOR SUPPORT (LS & GREP)
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# ---------------------------------------------------------
# PROMPT (Dynamic MacFlow Style)
# ---------------------------------------------------------
# Logic adapted from /etc/profile.d/custom-bash-options.sh
# \w = Full working directory (e.g., ~/macFlow/dotfiles)
if [[ "${UID}" == 0 ]]; then
    # ROOT: Red User, Green Host
    PS1='[\[\e[1;31m\]\u\[\e[m\]@\[\e[1;32m\]\h\[\e[m\] \[\e[1m\]\w\[\e[m\]] \$ '
else
    # USER: Green User, Green Host
    PS1='[\[\e[1;32m\]\u\[\e[m\]@\[\e[1;32m\]\h\[\e[m\] \[\e[1m\]\w\[\e[m\]] \$ '
fi

# ALIASES

# System & Session
alias ..='cd ..'
alias ...='cd ../..'
alias a='alias'
alias desktop='dbus-run-session Hyprland'
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alFh'
alias sbp='source ~/.bash_profile'
alias sbrc='source ~/.bashrc'
alias trunc='truncate -s 0'

# Git Shortcuts
alias gs='git status'
alias ga='git add -A'
alias gc='git commit -v'
alias gp='git push'
alias gco='git checkout'
alias gcm='git checkout main || git checkout master'

# Applications (VS Code: Force Wayland)
alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'

# Hyprland Display Management
alias displayInfo='hyprctl monitors'
alias displayReload='hyprctl reload'
alias displayReloadWaybar='killall waybar && waybar & disown'

# Resolution Presets (UTM/VirtIO)
alias displayResolutionMBA='wlr-randr --output Virtual-1 --custom-mode 2880x1864 --scale 2'
alias displayResolution4K='wlr-randr --output Virtual-1 --custom-mode 3840x2160 --scale 2'
alias displayResolution4Ksmall='wlr-randr --output Virtual-1 --custom-mode 3840x2160 --scale 1.5'
alias displayResolution2560x1440='wlr-randr --output Virtual-1 --custom-mode 2560x1440 --scale 2'
