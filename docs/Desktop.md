# macFlow Desktop

The `macFlow` desktop is a **Workflow Module**, not a full Linux distribution.

It brings a pure, uncompromised Linux development experience to the Mac, optimized for the constraints of virtualization on Apple Silicon.

## Strategy

For the **Desktop Mode**, we utilize **UTM** to gain access to **Hardware Acceleration** (`virtio-gpu`), but we configure Hyprland for maximum efficiency.

- **The Engine:** We use Hyprland for its **Dynamic Tiling Engine (Dwindle Layout)**, offering superior automatic layout logic compared to manual tilers.
- **The Mechanics:** We keep the "Muscle Memory" (Keybindings, Wofi, Waybar) of a modern Linux desktop.
- **The Trade-off:** We disable **Blur, Drop Shadows, and Animations** to ensure the VM feels responsive and snappy, prioritizing function over form.

## The Development "Flow"

We treat the interaction with the OS as "Modal"—you are either in **Development** mode or **Admin** mode.

The `macFlow` Desktop experience is designed to provide the mechanical efficiency of a Tiling Window Manager (TWM) without fighting the macOS WindowServer.

- **Keyboard-Centric:** A workflow optimized for muscle memory and dynamic window tiling, eliminating mouse dependency.
- **Pure Environment:** A distraction-free Linux user space dedicated solely for development tasks.
- **Seamless Integration:** Clipboard sync and file sharing between host and guest for a fluid experience.
- **Lightweight Footprint:** Minimal resource usage to preserve battery life and host performance.
- **Project Isolation:** With its small footprint, you can easily clone or spin up multiple separate VMs for different client projects or security contexts.

## The Bridge (Integration Points)

To ensure a seamless flow, `macFlow` uses standard protocols to bypass driver limitations on Apple Silicon:

- **Files:** Files are shared via **SSHFS**
- **Input:** Capture Input mode for keyboard/mouse focus
- **Clipboard:** Copy/Paste is handled via **SPICE**

For details, see [macFlow: File Integration](./Integration/macFlow-Integration.md).

## The "Safety Defusal"

By default, macOS intercepts many critical shortcuts (like `Cmd+Q` to quit) before they ever reach your Linux VM. This guide details how to "defuse" these shortcuts so they pass through to Hyprland safely.

**The Risk:** If your mouse is not fully captured by the VM, pressing **`Cmd + Q`** will instantly kill the UTM application and your running Linux session. This results in an improper shutdown, which may cause data loss or corrupt your Linux environment.

**The Fix:** We will remap these keyboard shortcuts specifically for the UTM application. This ensures that when you press them, macOS ignores the command, allowing Hyprland to receive the keystroke instead.

### Steps to Defuse

1. Open macOS **System Settings**.
2. Go to **Keyboard** > **Keyboard Shortcuts...**
3. Select **App Shortcuts** from the sidebar.
4. Click the **(+)** button to add a new shortcut.
5. **Application:** Select **UTM** from the list.
6. Add the following overrides:

| Menu Title (Exact Spelling) | Keyboard Shortcut      | Function                         |
| :-------------------------- | :--------------------- | :------------------------------- |
| **Quit UTM**                | `Cmd + Opt + Ctrl + Q` | Prevents accidental VM shutdown. |
| **Close**                   | `Cmd + Opt + Ctrl + W` | Prevents closing the VM window.  |

## Setting for Multiple Monitors

In your Hyprland config (`~/.config/hypr/hyprland.conf`) set it to your largest resolution.

```bash
monitor = , 3840x2160, auto, 2
#monitor = , 2880x1864, auto, 2
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
