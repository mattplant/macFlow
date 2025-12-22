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

### The File Bridge (SSHFS)

We use **SSHFS** (SSH Filesystem) to reliably share files between the Host (macOS) and Guest (Linux VM).

For details, see [macFlow: File Integration](./Integration/Files.md).

### Capture Input

By default, macOS intercepts many critical shortcuts (like `Cmd+Q` to quit) before they ever reach your Linux VM. This guide details how to "defuse" these shortcuts so they pass through to Hyprland safely.

#### The "Safety Defusal" (Critical)

**The Risk:** If your mouse is not fully captured by the VM, pressing **`Cmd + Q`** will instantly kill the UTM application and your running Linux session. This results in an improper shutdown, which may cause data loss or corrupt your Linux environment.

**The Fix:** We will remap these keyboard shortcuts specifically for the UTM application. This ensures that when you press them, macOS ignores the command, allowing Hyprland to receive the keystroke instead.

#### Steps to Defuse

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
