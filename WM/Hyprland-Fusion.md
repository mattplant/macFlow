# macFlow: Hyprland with VMware Fusion

> NOTE: We were unable to get Hyprland working using VMware Fusion on Apple Silicon (M4) due to fundamental compatibility issues with the graphics stack.
>
> See [Hyprland](./Hyprland.md) for alternative setup on UTM.

---

## ⛔ Compatibility Notice: Hyprland with VMware on Apple Silicon

**Current Status:** **Incompatible / Not Recommended**

Despite extensive configuration attempts, Hyprland is currently inviable on Arch Linux ARM running within VMware Fusion on Apple Silicon (M4).

### 1. Modern Hyprland (v0.52+ / Aquamarine)

- **Result:** Runtime Crash (Segmentation Fault).
- **The Error:** `[ERR] [AQ] [EGL] Command eglInitialize errored out... DRI2: failed to create screen`.
- **Root Cause:** Hyprland's internal rendering engine (**Aquamarine**) requires a compliant OpenGL/EGL context with specific DRM/GBM buffer management capabilities.
- **The Hardware Gap:** The VMware ARM graphics driver (`vmwgfx`) combined with the `llvmpipe` software renderer cannot satisfy these strict requirements. Even with "Nuclear" software overrides (`WLR_RENDERER_ALLOW_SOFTWARE=1`, `MESA_LOADER_DRIVER_OVERRIDE=llvmpipe`), the EGL initialization handshake fails, causing the compositor to segfault immediately on launch.

### 2. Legacy Hyprland (v0.40 / wlroots)

- **Result:** Compilation Failure.
- **The Error:** `error: too few arguments to function ‘liftoff_output_apply’`.
- **Root Cause:** **Library Drift.** The legacy source code relies on older versions of `wlroots` and `libliftoff`. Because Arch Linux is a rolling release, the system libraries have updated to newer API standards that are incompatible with the old source code.
- **The Cost:** Fixing this requires manually patching C code in the dependency tree, which violates the "Low Maintenance" goal of MacFlow.

### Options

Some options to explore.

#### Use Sway

**Sway** is the recommended Tiling Window Manager for this architecture.

- It natively supports the **Pixman** renderer (Pure CPU rendering).
- It does not require EGL/OpenGL to function.
- It is stable, performant on the M4 CPU, and available in standard repositories.

#### Explore other VMs

Consider alternative virtualization platforms that may offer better graphics support on Apple Silicon, such as `UTM` or `Parallels`.

---
---

# Original Hyprland Notes

Build notes for installing and configuring **Hyprland** in the `macFlow` project.

## Strategy: "Brutalist Hyprland"

To run smoothly on the Apple Silicon CPU (Software Rendering), we strictly disable the render pipeline features.

- **Animations/Blur/Shadows:** OFF (Saves CPU/GPU cycles)
- **Layout:** Dwindle (The "Omarchy" automatic tiling behavior)
- **Renderer:** `pixman` (Forced via environment variable)


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
```

## Environment Variables

Before configuring Hyprland, ensure your shell profile tells it to use Software Rendering.

- Edit Profile: ```nano ~/.bash_profile```

- Add/verify these lines exist:

```bash
# Force Software Rendering (Stable on Apple Silicon VMs)
export WLR_RENDERER=pixman

# Hyprland Specific: Tell Hyprland it is okay to use the CPU (Unlocks the gate)
export WLR_RENDERER_ALLOW_SOFTWARE=1

# Fix invisible mouse cursor (VMware bug)
export WLR_NO_HARDWARE_CURSORS=1
```

- Reload: ```source ~/.bash_profile```

## The "Brutalist" Configuration

We will create a config that forces the "Omarchy"-like layout but strips the heavy visuals.

- Create Directory: ```mkdir -p ~/.config/hypr```
- Edit Config: ```nano ~/.config/hypr/hyprland.conf```
- Paste the following:

```bash
# --- macFlow: Brutalist Hyprland Config ---

# Display (Manual Retina Scaling)
# Since VMCI is missing, we hardcode the resolution.
# Use 'wlr-randr' to find supported modes if 2560x1600 doesn't work.
monitor=Virtual-1, 2560x1600@60, 0x0, 2

# Input (Mac Feel)
input {
    kb_layout = us
    follow_mouse = 1
    natural_scroll = true

    touchpad {
        natural_scroll = true
    }
}

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
# CRITICAL: Disable "Eye Candy" to run smoothly on Apple Silicon CPUs
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

# Keybindings (Command Key = SUPER)
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

# 6. Autostart Services
exec-once = dunst
exec-once = waybar
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
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
Hyprland
```

*Note the Capital "H" in the command.*

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
