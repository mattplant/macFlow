# macFlow: Install Hyprland

Build notes for installing and configuring **Hyprland** in the `macFlow` project.

*Note:* For the `macFlow` desktop philosophy see [macFlow Desktop](../Desktop.md).

## Prerequisites

Desktop Mode builds on top of the base configuration. Before running this, complete
[Arch Linux Configuration](../Guest-OS/Arch-Configure.md) — the Hyprland script assumes
`yay` and the stowed dotfiles are already in place.

## Install Hyprland & Tools

Run the Hyprland install script. It installs the compositor, UI tools, terminal, fonts,
and the clipboard bridge, then configures `seatd`.

```bash
~/macFlow/scripts/installHyprland.sh
```

## Reboot, Then Start the Desktop

**A reboot is required** — the script adds your user to the `seat` group, and group
membership only takes effect at login. Without it Hyprland exits immediately with
*"No backend was able to open a seat"*.

```bash
sudo reboot
```

After logging back in at the TTY:

```bash
desktop        # alias for: uwsm start -- Hyprland
```

## Usage, Tips & Tricks

For usage including the "Safety Defusal" steps, see [macFlow Desktop](../Desktop.md).
