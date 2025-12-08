# macFlow: Sway

Build notes and troubleshooting documentation for using **Sway** in the macFlow project.

> **Note:** This is an alternative to the [Hyprland](Hyprland.md) setup. It offers a more "vanilla," stable tiling experience with lower overhead, though it lacks the dynamic layouts of Hyprland.

## Install Packages

We install the compositor, a fast CPU-native terminal (Foot), and essential UI tools.

```bash
# - sway: The window manager
# - swaybg: Required for setting wallpapers
# - foot: A lightweight Wayland terminal (Fastest on CPU rendering)
# - wofi: Application launcher (Replacement for Spotlight/Alfred)
# - xorg-xwayland: Compatibility layer for non-Wayland apps (VSCode/Electron)
# - ttf-dejavu: Basic font set to ensure text renders
# - waybar: Status bar (Sway has a basic one, but Waybar is more configurable)
yay -Syu sway swaybg foot wofi xorg-xwayland ttf-dejavu waybar
```

## Configure Sway

Sway requires a config file to function comfortably. We will copy the default system template and modify it for our workflow.

```bash
# Create config directory
mkdir -p ~/.config/sway

# Copy default config template
cp /etc/sway/config ~/.config/sway/config

# Open for editing
nano ~/.config/sway/config
```

Edits to make inside `~/.config/sway/config`:

- Set Modifier to Command Key
  - Find: `set $mod Mod4`
  - Verify: It should be Mod4 (This maps to the **Command ⌘** key on Mac keyboards).

- Set Applications
  - Find: `set $term ...`
  - Verify: It should be set to: ```set $term foot```
  - Find: `set $menu dmenu_path ...`
  - Change to: set `$menu wofi --show drun`

- Display (Retina Fix)
  - Because the WMCI driver is missing, auto-resize does not work. We must force a HiDPl resolution and scale.
    - Scroll to the bottom of the file.
    - Add the following lines

```config
# Specific fix for VMware Retina Scaling
output Virtual-1 scale 2
```

- Input (Natural Scrolling)
  - Find the section starting with `# Input configuration`
  - Add the following lines to enable natural scrolling on touchpads:

```config
input * {
    natural_scroll enabled
    tap enabled
}
```

- Save and Exit (Ctrl+O, Enter, Ctrl+X)

## Force Software Rendering

Since the M4 GPU drivers for Linux do not fully support Wayland 3D acceleration yet, we must force the Pixman (Software) renderer to prevent crashing.

- Edit your shell profile with ```nano ~/.bash_profile```
- Add these lines to the bottom:

```config
export WLR_RENDERER=pixman
```

Apply the changes immediately: ```source ~/.bash_profile```

## Internal Wayland Clipboard Support

Ensure the Wayland clipboard utility is installed for internal copy/paste between Linux windows (Terminal ↔ VSCode)

```bash
yay -S wl-clipboard
```

## Launch Sway

```bash
sway
```

## Sway Cheat Sheet

| Action            | Shortcut                          |
| :---------------- | :-------------------------------- |
| **Open Terminal** | `Cmd + Enter`                     |
| **Open Launcher** | `Cmd + d`                         |
| **Close Window**  | `Cmd + Shift + q`                 |
| **Move Focus**    | `Cmd + Arrow Keys` (or `h,j,k,l`) |
| **Move Window**   | `Cmd + Shift + Arrow Keys`        |
| **Reload Config** | `Cmd + Shift + c`                 |
| **Exit Sway**     | `Cmd + Shift + e`                 |
