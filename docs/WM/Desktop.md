# macFlow Desktop

The `macFlow` desktop is a **Workflow Module**, not a distribution.

It brings a pure, uncompromised Linux development experience to the Mac, optimized for the constraints of virtualization on Apple Silicon.

## Strategy: "Brutalist Hyprland"

For the **Desktop Mode**, we utilize **UTM** to gain access to **Hardware Acceleration** (`virtio-gpu`), but we configure Hyprland for maximum efficiency.

- **The Engine:** We use Hyprland for its **Dynamic Tiling Engine (Dwindle Layout)**, offering superior automatic layout logic compared to manual tilers.
- **The Mechanics:** We keep the "Muscle Memory" (Keybindings, Wofi, Waybar) of a modern Linux desktop.
- **The Trade-off:** We disable **Blur, Drop Shadows, and Animations** to ensure the VM feels responsive and snappy, prioritizing function over form.

## The Development "Flow"

We treat the interaction with the OS as "Modal"—you are either in **Development** mode or **Admin** mode.

The `macFlow` Desktop experience is designed to provide the mechanical efficiency of a Tiling Window Manager (TWM) without fighting the macOS WindowServer.

- **Keyboard-Centric:** A workflow optimized for muscle memory and dynamic window tiling, eliminating mouse dependency.
- **Pure Environment:** A distraction-free Linux user space dedicated solely to code.
- **Project Isolation:** With its small footprint, you can easily clone or spin up multiple separate VMs for different client projects or security contexts.

## Capture Input

For a distraction-free development flow, click the **Capture Mouse** (aka "*Capture Input Devices*") icon in the UTM toolbar to engage the fully isolated mode.

You can toggle this mode instantly by pressing `Control` + `Option` (Left side). This captures both the mouse and the keyboard.

### Why use Capture Mode?

- **Visual Focus:** It prevents the macOS Dock from popping up at the bottom or the Menu Bar from sliding down from the top, keeping you fully immersed in the Linux environment.
- **Distraction Free:** It prevents host notifications from popping up on the monitor when in full-screen mode.
- **Mouse Containment:** It locks the cursor to the VM window (or screen when in full-screen mode).
- **Keyboard Priority:** It blocks macOS system shortcuts (like Spotlight or Mission Control), allowing you to repurpose those keys entirely for your internal Hyprland workflow. For example, it prevents `Cmd` + `W` from immediately closing the VM session.

In combination, this provides a highly intuitive and distraction-free development environment.
