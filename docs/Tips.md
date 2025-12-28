# macFlow Tips & Tricks

## All Modes

### Safe Shutdown Procedure

Shut down Linux gracefully from within the guest OS to avoid data loss or corruption.

This can be done by many different ways including:

- terminal commands like `sudo poweroff` or `sudo reboot`
- graphical menus within your Linux desktop environment
- or request it thru the UTM app menu: **Virtual Machine** > **Power** > **Request power down**

You can also use but a more user-friendly way is to use Hyprland's built-in power menu.

## Desktop Mode

### Capture Input

For a distraction-free development flow, click the **Capture Mouse** (aka "*Capture Input Devices*") icon in the UTM toolbar or press `Control` + `Option` (Left side) to engage. Later press `Control` + `Option` (Left side) again to release.

#### Why Use Capture Mode?

- **Visual Focus:** It prevents the macOS Dock from popping up at the bottom or the Menu Bar from sliding down from the top, keeping you fully immersed in the Linux environment.
- **Distraction Free:** It prevents host notifications from popping up on the monitor when in full-screen mode.
- **Mouse Containment:** It locks the cursor to the VM window (or screen when in full-screen mode).
- **Keyboard Priority:** It blocks macOS system shortcuts (like Spotlight or Mission Control), allowing you to repurpose those keys entirely for your internal Hyprland workflow. And it allows those shortcuts to work properly inside the VM.

I also highly recommend [setting up the "safety defusal" keyboard shortcuts](./Desktop.md#the-safety-defusal-critical) to prevent accidental VM termination.
