# macFlow: Hyprland

Build notes for installing and configuring **Hyprland** in the `macFlow` project.

## Install Hyprland & Tools

Install the compositor and the necessary ecosystem tools.

```bash
# Core Desktop
# - hyprland: The engine
# - xorg-xwayland: Compatibility for non-Wayland apps (VSCode)
# - qt5-wayland / qt6-wayland: Sharp text for Qt apps
# - polkit-gnome: Password prompt agent (GTK styling)
yay -S hyprland xorg-xwayland qt5-wayland qt6-wayland polkit-gnome

# UI Elements
# - waybar: Status bar (Hyprland has none built-in)
# - dunst: Notifications
# - wofi: App Launcher
# - hyprpaper: Wallpaper utility
# We include pipewire-jack explicitly to avoid the "jack2 vs pipewire-jack" prompt
yay -S waybar dunst wofi hyprpaper pipewire-jack

# Terminal & Fonts
# - foot: CPU-native Wayland terminal (Fastest for VMs)
# - ttf-jetbrains-mono-nerd: Developer font
# - ttf-dejavu: UI Fallback font
yay -S foot ttf-jetbrains-mono-nerd ttf-dejavu

# Optional: Configuration tools to make Qt apps look like GTK apps
yay -S qt5ct qt6ct
```

## Environment Variables

Before configuring Hyprland, ensure your shell profile tells it to use Software Rendering.

- Edit Profile: ```nano ~/.bash_profile```

- Add/verify these lines exist:

```bash
# Fix invisible mouse cursor
export WLR_NO_HARDWARE_CURSORS=1

# Hyprland Specific: Tell Hyprland it is okay to use the CPU (Unlocks the gate)
export WLR_RENDERER_ALLOW_SOFTWARE=1
```

- Reload: ```source ~/.bash_profile```

## Fix: Hyprland Crashes on Startup

### Problem: Hyprland Fails to Start with Seat Error

When you try to launch Hyprland, it immediately exits with an
Error: "No backend was able to open a seat".

This means Hyprland (specifically the Aquamarine backend) is trying to access the hardware (the "Seat"), but it is being blocked by a permissions issue or a missing service.

Hyprland relies on seatd or logind (part of systemd) to gain access to the GPU/Input devices without being root. Since seatd failed and logind failed, Hyprland has no permission to draw to the screen, so it crashes.

### The Fix: Grant Seat Permissions

We need to ensure your user (macflow) is in the correct group (seat) and that the seatd service is running.

```bash
# Install seatd (if missing)
sudo pacman -S seatd

# Add user to seat group
sudo usermod -aG seat macflow

# Enable and Start the seatd service
sudo systemctl enable --now seatd

# Reboot
# Group changes require a re-login/reboot to take effect.
sudo reboot
```

## The "Brutalist" Configuration

We will create a config that forces the "Omarchy"-like layout but strip the heavy visuals.

This configuration assumes:

- **UTM Settings:** Display is set to `virtio-gpu-gl-pci` (not `ramfb`).
- **Drivers:** You installed mesa, spice-vdagent, and hyprland.
- **Philosophy:** "Brutalist" (No blur/shadows/animations) for maximum stability on the VM.

- Create Directory: ```mkdir -p ~/.config/hypr```
- Edit Config: ```nano ~/.config/hypr/hyprland.conf```
- Paste the following:

```bash
# --- MacFlow: Hyprland with UTM / VirtIO Config ---

# Display: Dynamic Resizing (The UTM Advantage)
# "preferred" tells Hyprland to use whatever resolution the UTM window is resized to.
# "auto" positions it automatically.
# "2" scales it for Retina (HiDPI). Change to "1" if you want massive screen real estate.
monitor=,preferred,auto,2

# Input (Mac Feel)
input {
    kb_layout = us
    follow_mouse = 1

    # Natural Scrolling for Mouse and Trackpad
    natural_scroll = true
    touchpad {
        natural_scroll = true
        tap-to-click = true
    }
}
    # Sensitivity (Optional tweak for VM mouse feel)
    sensitivity = 0
}

# 3. VM Integration (Critical)
# Fix for invisible cursor on VMs
env = WLR_NO_HARDWARE_CURSORS,1

# Start SPICE Agent for Clipboard & Auto-Resize
exec-once = systemctl --user start spice-vdagent

# Layout (The "Omarchy" Dwindle)
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2

    # Mac-like colors (Blue/Green active, Grey inactive)
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)

    layout = dwindle
}

dwindle {
    pseudotile = true
    preserve_split = true
}

# Performance (THE BRUTALIST SECTION)
# Disable expensive effects for rock-solid VM performance
decoration {
    rounding = 5
    blur {
        enabled = false
    }
    shadow {
        enabled = false
    }
}

animations {
    enabled = false
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    vfr = true  # Variable Frame Rate (Saves resources)
}

# Variables
$terminal = foot
$menu = wofi --show drun

# Keybindings
# (Command Key = SUPER)
$mainMod = SUPER

# Apps
bind = $mainMod, RETURN, exec, $terminal
bind = $mainMod, D, exec, $menu
bind = $mainMod, B, exec, firefox
bind = $mainMod, C, exec, code

# Window Management
bind = $mainMod, Q, killactive,
bind = $mainMod SHIFT, E, exit,
bind = $mainMod, F, togglefloating,
bind = $mainMod, P, pseudo, # dwindle
bind = $mainMod, J, togglesplit, # dwindle

# Focus (Vim style)
bind = $mainMod, h, movefocus, l
bind = $mainMod, l, movefocus, r
bind = $mainMod, k, movefocus, u
bind = $mainMod, j, movefocus, d

# Move Windows
bind = $mainMod SHIFT, h, movewindow, l
bind = $mainMod SHIFT, l, movewindow, r
bind = $mainMod SHIFT, k, movewindow, u
bind = $mainMod SHIFT, j, movewindow, d

# Autostart Services
exec-once = dunst
exec-once = waybar
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
# Mount Mac files (using the function from .bash_profile doesn't work here, use raw command)
# exec-once = sshfs ... (Add your mount command here if you want auto-mount)
```

### Mount macOS Shared Folder if Needed

If we autostart Hyprland than we have to also mount the macOS shared folder. If so then we need to add this line to the bottom of the config (Replace with your specific details):

```bash

# Mount Mac files
# Note: We must use the full command here because .bash_profile functions aren't loaded
exec-once = fusermount3 -u ~/macFlow; sshfs matt@CSW020.local:/Users/matt/macFlow ~/macFlow -o allow_other,reconnect,uid=$(id -u),gid=$(id -g)
```

## Launch Hyprland

From the TTY (Login screen):

```bash
dbus-run-session Hyprland
```

---

## Host Integration (Clipboard & Resize)

Due to race conditions and broken internal X11/Wayland bridging on ARM64, we need dedicated scripts to handle the Host-Guest communication via the X11 backend.

### Install Dependencies

Tools to bridge the X11 and Wayland clipboards.

```bash
yay -S xclip clipnotify
```

#### XWayland Configuration

We explicitly enable XWayland and disable scaling to ensure legacy X11 apps (like the SPICE agent) render correctly on Retina displays.

```bash
# Ensure XWayland is installed
yay -S xorg-xwayland
```

*Note:* See below for Hyprland config changes.

### Disable Default Autostart

Prevent the system from launching the unconfigured agent.

```bash
mkdir -p ~/.config/autostart
cp /etc/xdg/autostart/spice-vdagent.desktop ~/.config/autostart/
echo "Hidden=true" >> ~/.config/autostart/spice-vdagent.desktop
```

### Create Support Scripts

#### The Smart Watchdog (Mac ➔ VM)

- **File:** ~/.local/bin/clipboard-sync
- **Logic:** Watches X11. If it changes (and isn't empty), syncs to Wayland.

```bash
#!/bin/bash
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-1
LOG="/tmp/clipboard-sync.log"

while clipnotify -s clipboard; do
    X_CONTENT=$(xclip -o -selection clipboard 2>/dev/null)

    # Safety: Ignore empty X11 buffers to prevent clobbering Wayland
    if [ -n "$X_CONTENT" ]; then
        W_CONTENT=$(wl-paste 2>/dev/null)
        if [ "$X_CONTENT" != "$W_CONTENT" ]; then
            echo -n "$X_CONTENT" | wl-copy 2>/dev/null
        fi
    fi
done
```

#### The Export Helper (VM ➔ Mac)

- **File:** ~/.local/bin/clipboard-export
- **Logic:** Pauses the watchdog to prevent loops, writes to X11, then resumes.

```bash
#!/bin/bash
export DISPLAY=:0

# Pause the watchdog
pkill -STOP -f "clipboard-sync"

# Write to X11 (Clipboard + Primary)
CONTENT=$(wl-paste)
echo -n "$CONTENT" | xclip -i -selection clipboard
echo -n "$CONTENT" | xclip -i -selection primary

# Resume the watcher
pkill -CONT -f "clipboard-sync"
```

#### The Master Starter (start-spice)

- **File:** ~/.local/bin/start-spice
- **Logic:** Waits for XWayland socket before launching components.

```bash
#!/bin/bash
LOG="/tmp/spice-debug.log"

# 1. Aggressive Cleanup
killall -9 spice-vdagent clipboard-sync 2>/dev/null
sleep 0.5

# 2. Wait for XWayland Socket
for i in {1..40}; do
    if [ -e /tmp/.X11-unix/X0 ]; then
        break
    fi
    sleep 0.5
done

# 3. Start Components
(export DISPLAY=:0; ~/.local/bin/clipboard-sync) &

export GDK_BACKEND=x11
export DISPLAY=:0
exec spice-vdagent -x >> $LOG 2>&1
```

### Make Scripts Executable

```bash
chmod +x ~/.local/bin/clipboard-sync ~/.local/bin/clipboard-export ~/.local/bin/start-spice
```

### Update Hyprland Config

Add the following to `~/.config/hypr/hyprland.conf`:

```bash

# XWayland Configuration
xwayland {
    enabled = true
    force_zero_scaling = true
}

#...

# Keybinding for Manual Export (VM -> Mac)
bind = $mainMod SHIFT, C, exec, ~/.local/bin/clipboard-export

#...

# Autostart Spice Agent (Host Integration)
# Update Environment
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
# Launch Host Integration
exec-once = /home/macflow/.local/bin/start-spice
```

## Display Configuration (Troubleshooting & Fine-Tuning)

If the resolution in the config above doesn't work or look right, use `wlr-randr` to find a better mode supported by your hardware.

```bash
# Install tool
yay -S wlr-randr

# Identify & Test Modes
# List available resolutions and test them live to find your preference.

# List all supported modes (Run this inside Hyprland)
wlr-randr

# TEST: "Safe" Retina (2560x1600)
# Matches 13" MacBook Air native resolution
wlr-randr --output Virtual-1 --custom-mode 2560x1600 --scale 2

# TEST: "4K" Crisp (3840x2160)
# Maximum workspace space (Effective 1080p HiDPI)
wlr-randr --output Virtual-1 --custom-mode 3840x2160 --scale 2
```

### Fractional Scaling

You can use fractional scaling (e.g., `1.5`) if you need a balance between crispness and screen real estate.

⚠️ The "Blur" Trade-off:

- **Integer (Scale 2):** Pixel-perfect, crisp, computationally cheap.
- **Fractional (Scale 1.5):** Requires the GPU/CPU to render at a higher resolution and downsample. This consumes more resources and can result in slightly blurry text in XWayland apps.

```bash
# Test 1.5x Scaling
wlr-randr --output Virtual-1 --custom-mode 2560x1600 --scale 1.5
```
