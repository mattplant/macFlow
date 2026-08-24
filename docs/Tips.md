# macFlow Tips & Tricks

## All Modes

### Safe Shutdown Procedure

Shut down Linux gracefully from within the guest OS to avoid data loss or corruption.

There are several ways:

- terminal commands like `sudo poweroff` or `sudo reboot`
- or request it through the UTM app menu: **Virtual Machine** > **Power** > **Request power down** (sends ACPI, which the guest handles gracefully)

**Avoid** closing the UTM window or force-stopping the VM — that is a hard power cut
and risks filesystem corruption.

### Exiting Hyprland (Desktop Mode)

The desktop runs as a **uwsm-managed systemd session**, not a bare compositor:

```text
wayland-wm@Hyprland.service       Main service for Hyprland
wayland-wm-env@Hyprland.service   Environment preloader
graphical-session.target
```

Two safe ways out, both returning you to the TTY:

| | |
| :-- | :-- |
| `Super + Shift + Q` | The configured keybinding. Hyprland is the service's main process, so systemd unwinds `graphical-session.target` when it exits. |
| `uwsm stop` | The explicit route. Unwinds the unit tree in order rather than relying on the compositor exiting first — useful if something is wedged. |

Then `sudo poweroff` from the TTY.

Hyprland has no built-in power menu.

> ⚠️ `Cmd + Q` with the mouse uncaptured quits **UTM itself**, killing the VM instantly.
> See [the "Safety Defusal"](./Desktop.md#the-safety-defusal) for how to disarm it.

## Desktop Mode

### Capture Input

For a distraction-free development flow, click the **Capture Mouse** (aka "*Capture Input Devices*") icon in the UTM toolbar or press `Control` + `Option` (Left side) to engage. Later press `Control` + `Option` (Left side) again to release.

#### Why Use Capture Mode?

- **Visual Focus:** It prevents the macOS Dock from popping up at the bottom or the Menu Bar from sliding down from the top, keeping you fully immersed in the Linux environment.
- **Distraction Free:** It prevents host notifications from popping up on the monitor when in full-screen mode.
- **Mouse Containment:** It locks the cursor to the VM window (or screen when in full-screen mode).
- **Keyboard Priority:** It blocks macOS system shortcuts (like Spotlight or Mission Control), allowing you to repurpose those keys entirely for your internal Hyprland workflow. And it allows those shortcuts to work properly inside the VM.

I also highly recommend [setting up the "safety defusal" keyboard shortcuts](./Desktop.md#the-safety-defusal) to prevent accidental VM termination.
