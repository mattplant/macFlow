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

## Host Integration (Clipboard & Resize)
# - xclip: Clipboard sync
# - clipnotify: Clipboard watcher
# - xorg-xwayland: Ensure XWayland is available for legacy X11 apps (like the SPICE agent)
yay -S xclip clipnotify xorg-xwayland

# Optional: Configuration tools to make Qt apps look like GTK apps
yay -S qt5ct qt6ct
```

## Disable Default Autostart

Prevent the system from launching the unconfigured agent.

```bash
mkdir -p ~/.config/autostart
cp /etc/xdg/autostart/spice-vdagent.desktop ~/.config/autostart/
echo "Hidden=true" >> ~/.config/autostart/spice-vdagent.desktop
```

## Deploy Configurations (Dotfiles)

Instead of creating configuration files manually, we deploy the pre-configured "Brutalist" setup directly from the macFlow repository using **GNU Stow**.

### Prerequisites

Ensure you have cloned the repo into your home directory:

```bash
cd ~
git clone https://github.com/mattplant/macFlow.git
```

### Apply Configurations

Link the configurations from the repo to your system:

```bash
cd ~/macFlow/dotfiles

# 1. Link Window Manager & UI (Hyprland, Waybar, Wofi, Dunst)
stow -t ~hypr

# 2. Link Shell & Terminal (Foot)
stow -t ~ shell foot

# 3. Link Integration Scripts (Clipboard & Utils)
stow -t ~ scripts
```

*Result:* The config files are now symlinks to the repo. Not is this a quick way to add new configurations, but it also keeps them version-controlled and easy to update.

## Configuration Breakdown

The following sections explain the configuration you just deployed. You do not need to create these files manually.

### The "Brutalist" Hyprland Config

**File:** ~/.config/hypr/hyprland.conf

This configuration assumes:

- **UTM Settings:** Display is set to `virtio-gpu-gl-pci` (not `ramfb`).
- **Drivers:** You installed mesa, spice-vdagent, and hyprland.
- **Philosophy:** "Brutalist" (No blur/shadows/animations) for maximum stability on the VM.

We leverage an "Omarchy"-like config but strip heavy visuals for VM stability.

- **Monitor:** Auto-scales to UTM window size
- **Input:** Natural scrolling, touchpad tap-to-click
- **Layout:** Dwindle (Dynamic tiling)
- **Animations/Blur:** Disabled for performance (virtio-gpu optimization)
- **Keybindings:** Cmd key, apps, window management, and focus navigation
- **Autostart Services:** Clipboard sync, Dunst, Waybar, auth & SPICE agent

### Host Integration Scripts

**Location:** ~/.local/bin/

The stow scripts command deployed the following tools to handle the Host-Guest integration.

Due to race conditions and broken internal X11/Wayland bridging on ARM64, we need dedicated scripts to handle the Host-Guest communication via the X11 backend.

- **start-spice:** The master orchestrator. It waits for the XWayland socket to appear before launching the clipboard agent to prevent race conditions.
- **clipboard-sync:** A watchdog that monitors the X11 clipboard and syncs changes to Wayland (Mac ➔ VM).
- **clipboard-export:** A helper script bound to Super+Shift+C that pushes Wayland text to the Mac clipboard (VM ➔ Mac).

### Environment Variables

**File:** ~/.bash_profile

Ensure your shell profile loads the VM-specific flags.

```bash
# Fix invisible mouse cursor
export WLR_NO_HARDWARE_CURSORS=1
```

Reload the profile to apply the changes.

```bash
source ~/.bash_profile
```

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

## Launch Hyprland

From the TTY (Login screen):

```bash
dbus-run-session Hyprland
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
