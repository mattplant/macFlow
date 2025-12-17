# macFlow: Hyprland

Build notes for installing and configuring **Hyprland** in the `macFlow` project.

*Note:* For the `macFlow` desktop philosophy see [macFlow Desktop](./Desktop.md).

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

# Host Integration (Clipboard & Resize)
# - xclip: Clipboard sync
# - clipnotify: Clipboard watcher
# - xorg-xwayland: Ensure XWayland is available for legacy X11 apps (like the SPICE agent)
yay -S xclip clipnotify xorg-xwayland

# (Optional) Configuration tools to make Qt apps look like GTK apps
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

# Link Window Manager & UI (Hyprland, Waybar, Wofi, Dunst)
stow -t ~ hypr

# Link Shell & Terminal (Foot)
stow -t ~ shell foot

# Link Integration Scripts (Clipboard & Utils)
stow -t ~ scripts

# Reload the profile to apply the changes
source ~/.bash_profile
``````

*Result:* The config files are now symlinks to the repo. Not only is this a quick way to add new configurations, but it also keeps them version-controlled and easy to update.

## Configuration Breakdown

The following sections explain the configuration you just deployed. You do not need to create these files manually.

### The "Brutalist" Hyprland Config

**File:** ~/.config/hypr/hyprland.conf

This configuration assumes:

- **UTM Settings:** Display is set to `virtio-gpu-gl-pci` (not `ramfb`).
- **Drivers:** You installed mesa, spice-vdagent, and hyprland.
- **Philosophy:** "Brutalist" (No blur/shadows/animations) for maximum stability on the VM.

We strip heavy visuals for VM stability.

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

## Setting for Multiple Monitors

In your Hyprland config (`~/.config/hypr/hyprland.conf`) set it to your largest resolution.

```bash
monitor = , 3840x2160, auto, 2
#monitor = , 2880x1864, auto, 2
```

## Launch Hyprland

From the TTY (Login screen):

```bash
dbus-run-session Hyprland
```

## Apply GTK Dark Mode

Set GTK apps and dialog boxes to dark mode.

```bash
# Install nwg-look
yay -S nwg-look gnome-themes-extra

# Run nwg-look
nwg-look
# Set the following per tab:
# - Widget: Select Adwaita-dark
# - Color Scheme: Check the box "Prefer Dark Theme"
# - Icons: Select Adwaita
# - Cursor: Select Adwaita (fixes the "X" cursor bug)
# Click "Apply" -> "Close"
```

## Adjust Resolution

To adjust resolutions for different monitors you can use the `wlr-randr` tool. For example:

2025 MacBook Air:

```bash
wlr-randr --output Virtual-1 --custom-mode 2880x1864 --scale 2
```

4k Monitor:

```bash
wlr-randr --output Virtual-1 --custom-mode 3840x2160 --scale 2
```

2560x1440 Monitor:

```bash
wlr-randr --output Virtual-1 --custom-mode 2560x1440 --scale 2
```

### Fractional Scaling

You can use fractional scaling (e.g., `1.5`) if you need a balance between crispness and screen real estate.

⚠️ The "Blur" Trade-off:

- **Integer (Scale 2):** Pixel-perfect, crisp, computationally cheap.
- **Fractional (Scale 1.5):** Requires the GPU/CPU to render at a higher resolution and downsample. This consumes more resources and can result in slightly blurry text in XWayland apps.

```bash
# Test 1.5x Scaling
#wlr-randr --output Virtual-1 --custom-mode 2560x1600 --scale 1.5
wlr-randr --output Virtual-1 --custom-mode 3840x2160 --scale 1.5
```

## Troubleshooting resolutions

### Tools

Use either ```hyprctl monitors``` or ```wlr-randr``` to get information about your connected displays.

### Stuck in low resolution?

If you are stuck at 1280x800 resolution then:

1) Make sure that the `Retina Mode` setting is checked in the UTM virtual machine settings.
2) Verify that the SPICE Agent is running without errors with:

```bash
systemctl status spice-vdagentd
```

### Boot Resolution (GRUB)

Another option is to set the UTM window to open at a specific resolution by default by editing the GRUB settings.

I found that 3840x2160 worked well on both my macBook and 4K monitors.  Specifically for my 2025 macBook Air this gives me a crisp 4K display in the UTM window with a scale of 2. It dynamically resized to 3420x2146 and is at least reporting to be refreshing at 75 Hz.
scale: 2.00

```bash
sudo nano /etc/default/grub
# Find: GRUB_CMDLINE_LINUX_DEFAULT="..."
# Add this to the end (inside the quotes): video=Virtual-1:2560x1600@60
# Example:
#GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet console=tty1 video=Virtual-1:2560x1600"
#GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet console=tty1 video=Virtual-1:3840x2160"
#GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet console=tty1 video=Virtual-1:3840x2160@60"

# Update GRUB config
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

#### Display Configuration (Troubleshooting & Fine-Tuning)

Switch to using dynamic scaling in your Hyprland config (`~/.config/hypr/hyprland.conf`) file

```bash
# 1. Display: Dynamic Resizing (The UTM Advantage)
# "preferred" tells Hyprland to use whatever resolution the UTM window is resized to.
# "auto" positions it automatically.
# "2" scales it for Retina (HiDPI). Change to "1" if you want massive screen real estate.
monitor=,preferred,auto,2
```

#### Optional "Force Enable" Flag (e) Fix

You can force a resolution then add an `e` at the end of the monitor line in your grub config.

*Note* This is also handy when switching between monitors then you need.

```bash
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet console=tty1 video=Virtual-1:3840x2160@60e"
```
