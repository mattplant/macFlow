#
# ~/.bash_profile
#

# Set Environment Variables first
export WLR_NO_HARDWARE_CURSORS=1
# Force Firefox to use Wayland backend
export MOZ_ENABLE_WAYLAND=1

# Aliases

# force VSCode to use Wayland backend (Ozone)
alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'

# Load interactive shell settings (aliases, prompt, colors)
[[ -f ~/.bashrc ]] && . ~/.bashrc
