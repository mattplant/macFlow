# macFlow

[![Docs License: CC BY 4.0](https://img.shields.io/badge/Docs_License-CC_BY_4.0-lightgrey.svg?logo=creativecommons)](./LICENSE-DOCS.md)
[![Source Code License: MIT](https://img.shields.io/badge/Source_Code-MIT-blue.svg?logo=open-source-initiative&logoColor=white)](./LICENSE)

> Mac Host. Omarchy-like Flow.

`macFlow` is a **Workflow Module**, not a distribution. It brings an Omarchy-like development experience to the Mac without the bloat to fit the constraints of virtualization.

## Design Philosophy

The core objective is to decouple the *Development Workflow* from the *Operating System*. We treat the machine as two distinct entities working in tandem.

### Stability & Host Integrity

The foundational goal is to maintain the reliability of modern Apple Silicon and the macOS ecosystem for everyday use, while leveraging a Linux VM for development tasks.

- **Host Integrity:** We keep macOS as the stable host for **critical functions** (Hardware drivers, Battery life, Wi-Fi stability) and high-performance native apps (Zoom, Teams, Office).
- **VM Performance:** We ensure the Linux environment remains lightweight and disposable.

### Efficiency & Workflow

The primary reason for using Linux is to gain the mechanical efficiency of a Tiling Window Manager (TWM) without fighting the macOS WindowServer.

- **Keyboard-Centric Flow:** It offers the muscle memory and tiling windows optimized for development flow.
- **Development Ready:** A focused environment pre-loaded with **Neovim**, **VSCode**, **Git**, and **Zsh**.

## Architecture: Office vs. Workbench

We connect the Host and Guest via a network bridge rather than fragile virtualization drivers.

| Domain           | Role              | Responsibility                                                                                                                |
| :--------------- | :---------------- | :---------------------------------------------------------------------------------------------------------------------------- |
| **Host** (macOS) | **The Office**    | **"Admin."**<br>• Communication (Outlook, Slack)<br>• Hardware Abstraction (Wi-Fi, Power)<br>• Security (FileVault, Firewall) |
| **Guest** (Arch) | **The Workbench** | **"The Flow."**<br>• **TWM:** Hyprland (VirtIO-GPU)<br>• **Code:** VSCode / Neovim<br>• **Terminal:** Foot / Zsh / Starship   |

### The Bridge (Integration)

To ensure a seamless flow, `macFlow` uses standard network protocols to bypass driver limitations on Apple Silicon:

- **Files:** macOS `~/macFlow` directory is mounted into the VM via **SSHFS**.
- **Clipboard:** Copy/Paste is handled via **SPICE** (Desktop Mode) or **SSH** (Headless Mode).
- **Identity:** Git credentials are passed via **SSH Agent Forwarding**.

## Design Philosophy: Desktop Mode

For the **Desktop Mode**, we utilize **UTM** to gain access to **Hardware Acceleration** (`virtio-gpu`), but we configure Hyprland for maximum efficiency.

- **The Engine:** We use Hyprland for its **Dynamic Tiling Engine (Dwindle Layout)**, offering superior automatic layout logic compared to manual tilers.
- **The Mechanics:** We keep the "Muscle Memory" (Keybindings, Wofi, Waybar) of a modern Linux desktop.
- **The Trade-off:** We disable **Blur, Drop Shadows, and Animations** to ensure the VM feels responsive and snappy, prioritizing function over form.

### The "Flow" Experience

The `macFlow` experience is designed to be distraction-free and keyboard-centric along with being modal:

- **Cmd + Tab (to UTM):** You enter the **Flow State**. Distractions are tiled away. You are in a pure Linux environment controlled entirely by the keyboard.
- **Cmd + Tab (to macOS):** You return to the **Admin State**. You answer emails, join calls, manage calendar events, and create presentations and other Office tasks.
- **Persistence:** The VM is persistent. You can disconnect, close the lid, or switch contexts, and the Linux layout remains exactly where you left it.

---

## Choose Your Flow

`macFlow` supports two distinct operating modes.

### "Headless" Mode (*The Core*)

- **What it is:** No Linux GUI. You use macOS native terminals (Ghostty/Kitty) and VSCode Remote to interact with the Linux engine.
- **Pros:** Extremely lightweight, max battery efficiency, zero maintenance, native macOS fonts/rendering.
- **Cons:** No tiling window manager logic; relies on macOS window management.

### Desktop Mode (*The Full Experience*)

- **What it is:** A full Tiling Window Manager environment inside the VM.
- **Pros:** The complete "Omarchy" tiling experience (Dwindle layout), distraction-free focus.
- **Cons:** Higher resource usage.

## Prerequisites

- **Hardware:** A modern Apple Silicon Mac running macOS.
- **Storage:** At least 40GB of free drive space (Less required for Headless-only setups).
- **Permissions:** Admin access for Network/Sharing settings.

## Build Steps

Every `macFlow` build requires these core steps:

- **VM Platform:** [UTM Setup](./VM/UTM.md)
- **Guest OS:** [Arch Linux ARM Installation](./Guest-OS/Arch.md)
- **Integration:** ["Headless" Bridge Setup](./Integration/Headless.md)
  - *Includes: SSH Access, File Sharing, and Git Identity.*

### The Desktop (*Optional*)

Proceed here if you want the graphical Tiling Window Manager flow.

- [**Window Manager:** Hyprland Setup](./WM/Hyprland.md)
  - *Includes: Host Integration (Clipboard), Keybindings, and Dwindle Layout.*
- [**Visuals:** Waybar & Styling](./WM/Styling.md)

### The Workbench (*Optional*)

Install the tools to enable efficient development work.

- [**Development Tools:** Neovim, VSCode, & Terminals](./Tools/Development.md)

## Directory Structure

```text
macFlow/
├── Guest-OS/       # Arch Linux ARM installation
├── Integration/    # SSH, SSHFS, and Bridge configuration
├── Tools/          # Neovim, VSCode, and Shell setup
├── VM/             # UTM configuration
├── WM/             # Hyprland and Waybar configs
├── LICENSE         # Source Code License (MIT)
├── LICENSE-DOCS.md # Documentation License (CC BY 4.0)
└── README.md       # You are here
