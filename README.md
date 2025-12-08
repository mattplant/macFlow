# macFlow

[![Docs License: CC BY 4.0](https://img.shields.io/badge/Docs_License-CC_BY_4.0-lightgrey.svg?logo=creativecommons)](./LICENSE-DOCS.md)
[![Source Code License: MIT](https://img.shields.io/badge/Source_Code-MIT-blue.svg?logo=open-source-initiative&logoColor=white)](./LICENSE)

> Mac Host. Omarchy-like Flow.

`macFlow` is a **Workflow Module**, not a distribution. It brings an Omarchy-like development experience to the Mac without the bloat to fit the constraints of virtualization.

## Design Philosophy

The core objective is to decouple the *Development Workflow* from the *Operating System*. We treat the machine as two distinct entities working in tandem.

### Stability & Host Integrity

The foundational goal is to maintain the reliability of modern Apple Silicon and the macOS ecosystem for everyday use, while leveraging a Linux VM for development tasks.

- **Host Integrity:** We keep `macOS` as the stable host for **critical functions** (Hardware drivers, Battery life, Wi-Fi stability) and high-performance native apps (Zoom, Teams, Office).
- **VM Performance:** We ensure the Linux environment remains lightweight and disposable.

### Efficiency & Workflow

The primary reason for using Linux is to gain the mechanical efficiency of a Tiling Window Manager (TWM) without fighting the macOS WindowServer.

- **Keyboard-Centric Flow:** It offers the muscle memory and tiling optimized for software rendering.
- **Development Ready:** A focused environment pre-loaded with **Neovim**, **VSCode**, **Git**, and **Zsh**.

## Architecture: Office vs. Workbench

We connect the Host and Guest via a network bridge rather than fragile virtualization drivers.

| Domain           | Role              | Responsibility                                                                                                                       |
| :--------------- | :---------------- | :----------------------------------------------------------------------------------------------------------------------------------- |
| **Host** (macOS) | **The Office**    | **Admin**<br>• Communication (Outlook, Slack)<br>• Hardware Abstraction (Wi-Fi, Power)<br>• Security (FileVault, Firewall)           |
| **Guest** (Arch) | **The Workbench** | **Development Flow**<br>• **TWM:** Sway (Software Rendered)<br>• **Code:** VSCode / Neovim<br>• **Terminal:** Kitty / Zsh / Starship |

### The Bridge (Integration)

To ensure a seamless flow, `macFlow` uses standard network protocols to bypass missing kernel drivers on Apple Silicon:

- **Files:** macOS `~/macFlow` directory is mounted into the VM via **SSHFS**.
- **Clipboard:** Copy/Paste is handled via **SSH** from the native macOS terminal.
- **Identity:** Git credentials are passed via **SSH Agent Forwarding**.

## Architecture

For the **Desktop Mode**, instead of fighting for hardware acceleration that is unstable on Apple Silicon VMs, `macFlow` embraces **Sway** using **Software Rendering (Pixman)**.

- **The Engine:** We use **Sway** because it natively supports the `pixman` (CPU) renderer without the strict OpenGL requirements that cause Hyprland to crash on this architecture.
- **The Mechanics:** We keep the "Muscle Memory" (Keybindings, Wofi, Waybar) of a modern Linux desktop but rely on the Apple Silicon single-core performance to brute-force a utilitarian, sharp, and glitch-free interface.
- **The Trade-off:** We sacrifice "Eye Candy" (Animations, Blur, Drop Shadows) to gain rock-solid stability.

### The Flow Experience

The `macFlow` experience is designed to be distraction-free and keyboard-centric along with being modal:

- **Cmd + Tab (to VMware):** You enter the **Flow State**. Distractions are tiled away. You are in a pure Linux environment controlled entirely by the keyboard.
- **Cmd + Tab (to macOS):** You return to the **Admin State**. You answer emails, join calls, manage calendar events, and create presentations and other Office documents.
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
- **Cons:** Higher resource usage, requires software rendering configuration.

## Prerequisites

- **Hardware:** A modern Apple Silicon Mac running macOS.
- **Storage:** At least 40GB of free drive space (Less required for Headless-only setups).
- **Permissions:** Admin access for Network/Sharing settings.

## Build Steps

Every `macFlow` build requires these core steps:

- [**VM Platform:** VMware Fusion Setup](./VM/Fusion.md)
- [**Guest OS:** Arch Linux ARM Installation](./Guest-OS/Arch.md)
- [**Integration:** "Headless" Bridge Setup](./Integration/Headless.md)
  - *Includes: SSH Access, File Sharing, and Git Identity.*

### The Desktop (*Optional*)

Proceed here if you want the graphical Tiling Window Manager flow.

- [**Window Manager:** Sway Setup](./WM/Sway.md)

### The Workbench (*Optional*)

Install the tools to enable efficient development work.

- [**Development Tools:** Neovim, VSCode, & Terminals](./Tools/Development.md)

## Directory Structure

```text
macFlow/
├── Guest-OS/       # Arch Linux ARM installation
├── Integration/    # SSH, SSHFS, and Bridge configuration
├── Tools/          # Neovim, VSCode, and Shell setup
├── WM/             # Window Manager (Sway) setup
├── LICENSE         # Source code license (MIT)
├── LICENSE.md      #
├── LICENSE-DOCS.md # Documentation license (CC BY 4.0)
└── README.md       # You are here
```

## 🏷️ Licensing & Attribution

`macFlow` applies a dual‑license model to balance strong copyleft protections with open documentation reuse:

| Component     | License                      | Details                                     |
| ------------- | ---------------------------- | ------------------------------------------- |
| Source Code   | [MIT](LICENSE.HIDE)          | See [`LICENSE`](./LICENSE.HIDE).            |
| Documentation | [CC BY 4.0](LICENSE-DOCS.md) | See [`LICENSE-DOCS.md`](./LICENSE-DOCS.md). |
