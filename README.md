# macFlow

[![Docs License: CC BY 4.0](https://img.shields.io/badge/Docs_License-CC_BY_4.0-lightgrey.svg?logo=creativecommons)](./LICENSE-DOCS.md)
[![Source Code License: MIT](https://img.shields.io/badge/Source_Code-MIT-blue.svg?logo=open-source-initiative&logoColor=white)](./LICENSE)

> Mac Host. Linux Development Flow.

## Design

The core objective is to maintain the reliability of the `macOS` for everyday use while leveraging **Linux VMs** for development.

- **Host Integrity:** We keep `macOS` as the stable host for **critical functions** (Hardware drivers, Battery life, Wi-Fi stability) and high-performance native apps (Zoom, Teams, Office).
- **VM Performance:** We ensure the Linux environments are fast, lightweight and disposable.

For more details, see [macFlow Reference Context](./docs/Reference.md).

## Choose Your Flow

`macFlow` supports two distinct operating modes.

### "Headless" Mode (*The Core*)

- **What it is:** No Linux GUI. You use macOS native terminals and VS Code Remote to interact with the **Linux VMs**.
- **Pros:** Extremely lightweight, max battery efficiency, low maintenance, native macOS fonts/rendering.
- **Cons:** No tiling window manager logic; relies on macOS window management.

### "Desktop" Mode (*The Full Experience*)

- **What it is:** A full Tiling Window Manager environment inside the Linux VM.
- **Pros:** The complete tiling experience (Dwindle layout), distraction-free focus.
- **Cons:** Higher resource usage than Headless.

> *Tip:* You can start with ["Headless"](./docs/Headless.md) for lightweight tasks, and switch to ["Desktop"](./docs/Desktop.md) mode later if needed.

## Installation

### Prerequisites

- **Hardware:** A modern Apple Silicon Mac running macOS.
- **Storage:** At least 20GB of free drive space (Less required for Headless-only mode).
- **Permissions:** Admin access for Network/Sharing settings.

### Choose a Build Path

The base Arch VM can be built two ways. Everything after it is identical.

- **Manual (default):** Step through the Archboot installer yourself, following the Core Setup below. Best the first time — you see what every layer does.
- **Automated (IaC):** Build a base image with a single `packer build`, then import it into UTM and skip the *Install Arch* step.
  - *See [Packer Base Image](./packer/README.md) for prerequisites and usage*

### Core ("Headless" Mode) Setup

- **Create VM:** Open UTM and create a new **Virtualize** machine for Linux
  - *See [UTM Setup](./docs/VM/UTM.md) for recommended settings*
- **Install Arch:** Boot the ISO and run the installer
  - *See [Arch Linux Install](./docs/Guest-OS/Arch-Install.md) for detailed steps*
- **Configure Arch:** Set up networking, users, and essential packages
  - *See [Arch Linux Configuration](./docs/Guest-OS/Arch-Configure.md) for detailed steps*
- **macFlow Integration:** Set up the integration bridge (Files, Clipboard, Identity)
  - *See [macFlow Integration](./docs/Integration/macFlow-Integration.md) for detailed steps*

### (Optional) "Desktop" Mode Setup

For the full tiling window manager experience, see:

- **Install Tiling WM:** Follow the steps in [Hyprland Install](./docs/WM/Hyprland.md) to set up window manager and related tools.

#### (Optional) Additional "Desktop" Enhancements

- **Configure Development Tools:** Set up VS Code, git, and other tools by following [Development Tools](./docs/Tools/Development.md).

### Troubleshooting

- **Tips & Tricks:** See [macFlow Tips & Tricks](docs/Tips.md).
- **Philosophy & Context:** See [macFlow Reference Context](docs/Reference.md).
