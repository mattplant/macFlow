# macFlow

[![Docs License: CC BY 4.0](https://img.shields.io/badge/Docs_License-CC_BY_4.0-lightgrey.svg?logo=creativecommons)](./LICENSE-DOCS.md)
[![Source Code License: MIT](https://img.shields.io/badge/Source_Code-MIT-blue.svg?logo=open-source-initiative&logoColor=white)](./LICENSE)

> Mac Host. Linux Development Flow.

## Prerequisites

- **Hardware:** A modern Apple Silicon Mac running macOS.
- **Storage:** At least 20GB of free drive space (Less required for Headless-only setups).
- **Permissions:** Admin access for Network/Sharing settings.

## Design Philosophy

The core objective is to decouple the *Development Workflow* from the *Operating System*. We treat the machine as two distinct entities working in tandem.

### Stability & Host Integrity

The foundational goal is to maintain the reliability of modern Apple Silicon and the macOS ecosystem for everyday use, while leveraging a Linux VM for development tasks.

- **Host Integrity:** We keep macOS as the stable host for **critical functions** (Hardware drivers, Battery life, Wi-Fi stability) and high-performance native apps (Zoom, Teams, Office).
- **VM Performance:** We ensure the Linux environment remains lightweight and disposable.

### The Bridge (Integration)

To ensure a seamless flow, `macFlow` uses standard protocols to bypass driver limitations on Apple Silicon:

- **Files:** macOS `~/macFlow` directory is mounted into the VM via **SSHFS**.
- **Clipboard:** Copy/Paste is handled via **SPICE** (Desktop Mode) or **SSH** (Headless Mode).
- **Identity:** Git credentials are passed via **SSH Agent Forwarding**.

We connect the Host and Guest via a network bridge rather than fragile virtualization drivers.

| Domain | Role | Responsibility |
| :--- | :--- | :--- |
| **Host** (macOS) | **The Office** | **"Admin."**<br>• Communication (Outlook, Slack)<br>• Hardware Abstraction (Wi-Fi, Power)<br>• Security (FileVault, Firewall) |
| **Guest** (Arch) | **The Workbench** | **"The Flow."**<br>• **TWM:** Hyprland (VirtIO-GPU)<br>• **Code:** VSCode / Neovim<br>• **Terminal:** Foot / Zsh / Starship |

## Choose Your Flow

`macFlow` supports two distinct operating modes.

### "Headless" Mode (*The Core*)

- **What it is:** No Linux GUI. You use macOS native terminals (Ghostty/Kitty) and VSCode Remote to interact with the Linux engine.
- **Pros:** Extremely lightweight, max battery efficiency, zero maintenance, native macOS fonts/rendering.
- **Cons:** No tiling window manager logic; relies on macOS window management.

### "Desktop" Mode (*The Full Experience*)

- **What it is:** A full Tiling Window Manager environment inside the VM.
- **Pros:** The complete tiling experience (Dwindle layout), distraction-free focus.
- **Cons:** Higher resource usage.

*Note:* For the desktop philosophy see [macFlow Desktop](./docs/WM/Desktop.md).

## Build Steps

Every `macFlow` build requires these core steps:

- **VM Platform:** [UTM Setup](./docs/VM/UTM.md)
- **Guest OS:**
  - [Arch Linux Installation](./docs/Guest-OS/Arch-Install.md)
  - [Arch Linux Configuration](./docs/Guest-OS/Arch-Configure.md)
- **Integration:** ["Headless" Bridge Setup](./docs/Integration/Headless.md)

### The Desktop (*Optional*)

- [Tiling Window Manager](./docs/WM/Hyprland.md)

### The Workbench (*Optional*)

Install the tools to enable efficient development work.

- [**Development Tools:** VSCode, git config, etc.](./docs/Tools/Development.md)

## Directory Structure

```text
macFlow/
├── docs/               # Documentation
│   ├── Guest-OS/       # Arch Linux installation and configuration
│   ├── Integration/    # SSH, SSHFS, and Bridge configuration
│   ├── Tools/          # VSCode, git config, etc.
│   ├── VM/             # UTM configuration
│   └── WM/             # Hyprland and Waybar configuration
├── dotfiles/           # Source configuration files (Stow targets)
├── LICENSE             # Source Code License (MIT)
├── LICENSE-DOCS.md     # Documentation License (CC BY 4.0)
└── README.md           # You are here
```