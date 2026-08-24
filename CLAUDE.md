# macFlow — Claude Code Guide

## Project Overview

**macFlow** is a setup guide and dotfile/tooling repository for a "Mac Host, Linux Development Flow" architecture. The goal: keep macOS stable and untouched for everyday use while running lightweight, disposable Arch Linux VMs for all development work.

## Operating Modes

- **Headless Mode:** No Linux GUI. macOS terminals + VS Code Remote SSH connect to the VM. Lightweight, best battery life.
- **Desktop Mode:** Full Hyprland (Wayland tiling WM) running inside the VM via UTM/SPICE.

## Repository Structure

```
macFlow/
├── docs/               # All documentation (Markdown)
│   ├── Guest-OS/       # Arch Linux install + configure
│   ├── Integration/    # SSHFS, clipboard, SSH agent bridge
│   ├── Tools/          # Dev tools (VS Code, git, Claude Code, etc.)
│   ├── VM/             # UTM setup
│   ├── WM/             # Hyprland, Waybar, Wofi
│   ├── Desktop.md      # Desktop Mode guide
│   ├── Headless.md     # Headless Mode guide
│   ├── Reference.md    # Design philosophy and reference
│   └── Tips.md         # Tips & Tricks
├── dotfiles/           # GNU Stow targets (deployed via `stow`)
│   ├── foot/           # Foot terminal config
│   ├── hypr/           # Hyprland, Waybar, Dunst, Wofi configs
│   ├── scripts/        # Shell utility scripts (clipboard, spice, macmount)
│   └── shell/          # .bashrc / .bash_profile
├── ansible/            # IaC: setup.yml, the guest configuration playbook
├── packer/             # IaC: Packer templates for automated VM builds
│   ├── macflow.pkr.hcl # Packer build definition (QEMU + ARM64)
│   └── scripts/        # Boot/install scripts served via HTTP during build
├── scripts/            # Guest-side scripts (configArch, connect_mac, installHyprland)
└── README.md
```

## Key Technical Context

- **Host:** Apple Silicon Mac (macOS). All hardware-sensitive tasks stay here.
- **Guest:** Arch Linux ARM64 inside UTM (QEMU with HVF acceleration).
- **Bridge:** Files via SSHFS, clipboard via SPICE (Desktop) or the terminal emulator (Headless), git identity via SSH Agent Forwarding.
- **Package manager in VM:** `yay` (AUR helper wrapping `pacman`).
- **Dotfile management:** GNU Stow — configs live in `dotfiles/` and are symlinked into `~` inside the VM.
- **IaC:** Packer builds the image (`packer/`); Ansible configures the guest (`ansible/setup.yml`). The playbook runs guest-side in both paths — via `ansible-local` during a Packer build, and via `scripts/configArch.sh` on a manual install.

## Documentation Conventions

- All docs are Markdown, written for humans following a step-by-step setup.
- Use `bash` fenced code blocks for all shell commands.
- Inline comments in code blocks explain *why*, not just *what*.
- Sections follow a consistent pattern: Strategy → Installation → Configuration.
- Keep docs accurate and minimal — avoid redundancy across files.

## Common Tasks

- **Adding a new tool:** Add an install section to `docs/Tools/Development.md` or the relevant doc. If it has dotfiles, add a stow target under `dotfiles/`.
- **Updating Hyprland config:** Edit files under `dotfiles/hypr/.config/hypr/` — they are the source of truth (stowed into the VM).
- **Updating Packer build:** Edit `packer/macflow.pkr.hcl` and/or `packer/scripts/install_base.sh`.
- **Changing guest configuration:** Edit `ansible/setup.yml` — never `scripts/configArch.sh`, which is only a wrapper around it.
- **Docs only:** Changes to `docs/` don't require VM testing unless they reference new scripts or config.
