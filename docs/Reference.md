# macFlow Reference Context

Reference documentation for the `macFlow` project.

## Design Philosophy

The core objective is to decouple the *Development Workflow* from the host *Operating System*. We treat the machine as two distinct entities working in tandem.

### Stability & Host Integrity

The foundational goal is to maintain the reliability of modern Apple Silicon and the macOS ecosystem for everyday use, while leveraging Linux VM(s) for development.

- **Host Integrity:** We keep macOS as the stable host for **critical functions** (Hardware drivers, Battery life, Wi-Fi stability) and high-performance native apps (Zoom, Teams, Office).
- **VM Performance:** We ensure the Linux environment remains lightweight and disposable.

## The Bridge (Integration Points)

To ensure a seamless flow, `macFlow` uses standard protocols to bypass driver limitations on Apple Silicon:

- **Files:** the macOS `~/macFlow-SHARE` folder is mounted inside the VM at `~/macFlow-HOST`, via **SSHFS**.
- **Clipboard:** Copy/Paste is handled via **SPICE** (Desktop Mode) or your **terminal emulator** (Headless Mode).
- **Identity:** Git credentials are passed via **SSH Agent Forwarding** (both modes).

## Modes

`macFlow` supports two distinct operating modes.

- **"Headless" Mode:** No Linux GUI. You use macOS native terminals and VS Code Remote to interact with the Linux engine. Extremely lightweight, max battery efficiency, zero maintenance, native macOS fonts/rendering. For more info, see [macFlow Headless](./Headless.md).
- **"Desktop" Mode:** A full Tiling Window Manager environment inside the VM. The complete tiling experience (Dwindle layout), distraction-free focus. For more info, see [macFlow Desktop](./Desktop.md).

*Tip:* You can start with "Headless" for lightweight tasks, and switch to "Desktop" mode later if needed.

## Linux Installation Notes

Key components with context of the `macFlow` Arch Linux installation.

- Required packages for for minimum system:
  - `base` - core OS
  - `iptables-nft` - firewall utilities
  - `linux-aarch64` - Linux kernel (Arch Linux ARM's aarch64 kernel)
  - `polkit` - privilege management
  - `btrfs-progs` - BTRFS filesystem tools
  - `dosfstools` - DOS filesystem utilities
  - `terminus-font` - console fonts
- We also installed these modules: `virtio virtio_pci virtio_blk virtio_net virtio_gpu virtio_balloon virtio_console`

## Linux Configuration Notes

**Source of truth:** [`ansible/setup.yml`](../ansible/setup.yml). This section explains
*why* each piece exists, not how to run it — the playbook is what actually runs, on both
install paths. Earlier versions of this file duplicated those commands and drifted out
of date, so the commands are gone rather than maintained in two places.

### Package Management (yay)

`yay` wraps `pacman` and adds AUR access.

- **Why it is needed:** Desktop Mode pulls VS Code's ARM64 binary and some fonts from
  the AUR. The *base* configuration does not need it — every package in `setup.yml`
  comes from `core`/`extra`.
- **Why it is bootstrapped by hand:** `yay` is itself an AUR package, so it must be
  built once with `makepkg` before it can install anything.
- **Why not `makepkg -si`:** `-s` shells out to `sudo` and blocks forever on a password
  prompt during an unattended build. The playbook installs the build dependencies
  first, runs `makepkg` as the unprivileged user, then installs the result as root.

### Drivers and Services

| Package | Why |
| :------ | :-- |
| `mesa` | 3D acceleration for `virtio-gpu` |
| `linux-aarch64-headers` | building out-of-tree kernel modules |
| `qemu-guest-agent` | host ↔ guest channel (what `utmctl exec` talks to) |
| `openssh` | remote access from macOS |
| `avahi`, `nss-mdns` | `.local` resolution, so `macflow.local` works |
| `sshfs` | mounting the macOS shared folder |
| `stow` | dotfile symlink management |

Two subtleties worth knowing:

- **`nsswitch.conf` ordering matters.** `mdns_minimal [NOTFOUND=return]` must sit after
  `files myhostname` and before `resolve`/`dns`. Wrong order silently breaks `.local`.
- **`qemu-guest-agent` is enabled but not always started.** Its unit requires the
  virtio-serial channel at `/dev/virtio-ports/org.qemu.guest_agent.0`. UTM provides it;
  a Packer build VM does not. The playbook always enables it and starts it only when
  the channel exists, so it comes up on the first boot under UTM.

### Dotfiles (GNU Stow)

Stow symlinks the packages under `dotfiles/` into `$HOME`:

- `shell` → `.bashrc`, `.bash_profile`
- `scripts` → utilities in `~/.local/bin/`
- `foot` → terminal config
- `hypr` → Hyprland, Waybar, Wofi, Dunst

*Consequence:* those files in `$HOME` are **symlinks into your clone of this repo**.
Editing `~/.bashrc` edits the repository. Change the file under `dotfiles/` instead,
then re-run `stow`.

Stow refuses to link over a real file, so the playbook first moves any pre-existing
`.bashrc` / `.bash_profile` / `.bash_login` aside to `.bak`.

### The File Bridge (SSHFS)

The mount is a shell function rather than an `/etc/fstab` entry, because an fstab mount
that cannot reach the Mac will hang boot.

- `macmount` / `macunmount` / `macstatus` live in
  [`dotfiles/shell/.bash_profile`](../dotfiles/shell/.bash_profile).
- The `host` alias in `~/.ssh/config` is written by
  [`scripts/connect_mac.sh`](../scripts/connect_mac.sh).
- `user_allow_other` in `/etc/fuse.conf` is what makes the uid/gid mapping work.

**`~/macFlow-HOST` stays read-only (`0500`) while unmounted.** Left writable it is an
ordinary directory: files saved there succeed, look completely normal, and never reach
your Mac. `macmount` opens it to `0700` only long enough to mount. `Permission denied`
writing there means the share is not mounted — run `macmount`.

## Hyprland Installation Notes

Key components with context of the `macFlow` Hyprland installation.

### Why These Packages

**Source of truth:** [`scripts/installHyprland.sh`](../scripts/installHyprland.sh).

- `hyprland` + `uwsm` — `uwsm` launches Hyprland as a managed systemd session, which is
  what the `desktop` alias runs.
- `xorg-xwayland` — compatibility for X11 apps, including the SPICE agent.
- `wl-clipboard`, `xclip`, `clipnotify` — the clipboard bridge needs both sides:
  Wayland (`wl-copy`/`wl-paste`) and X11.
- `spice-vdagent` — carries the clipboard to and from the Mac.
- `psmisc` — provides `killall`, used by `start-spice` to reap stale agents.
- `foot` — CPU-rendered Wayland terminal, the fastest option inside a VM.
- `pipewire-jack` — included explicitly to avoid an interactive `jack2` vs
  `pipewire-jack` prompt mid-install.
- `waybar`, `dunst`, `wofi`, `hyprpaper` — status bar, notifications, launcher,
  wallpaper. Hyprland ships none of these.

### The "Brutalist" Hyprland Config

**File:** ~/.config/hypr/hyprland.conf

This configuration assumes:

- **UTM Settings:** Display is set to `virtio-gpu-gl-pci` (not `ramfb`).
- **Drivers:** You installed mesa, spice-vdagent, and hyprland.
- **Philosophy:** "Brutalist" (No blur/shadows/animations) for maximum stability on the VM.

We strip heavy visuals for VM stability.

- **Monitor:** Auto-scales to UTM window size
- **Input:** Natural scrolling, touchpad tap-to-click
- **Layout:** Dwindle (Dynamic tiling)
- **Animations/Blur:** Disabled for performance (virtio-gpu optimization)
- **Keybindings:** Cmd key, apps, window management, and focus navigation
- **Autostart Services:** Clipboard sync, Dunst, Waybar, auth & SPICE agent

### Host Integration Scripts

**Location:** ~/.local/bin/

The stow scripts command deployed the following tools to handle the Host-Guest integration.

Due to race conditions and broken internal X11/Wayland bridging on ARM64, we need dedicated scripts to handle the Host-Guest communication via the X11 backend.

- **start-spice:** The master orchestrator. It waits for the XWayland socket to appear before launching the clipboard agent to prevent race conditions.
- **clipboard-sync:** A watchdog that monitors the X11 clipboard and syncs changes to Wayland (Mac ➔ VM).
- **clipboard-export:** A helper script bound to Super+Shift+C that pushes Wayland text to the Mac clipboard (VM ➔ Mac).

## Fix: Hyprland Crashes on Startup

### Problem: Hyprland Fails to Start with Seat Error

When you try to launch Hyprland, it immediately exits with an
Error: "No backend was able to open a seat".

This means Hyprland (specifically the Aquamarine backend) is trying to access the hardware (the "Seat"), but it is being blocked by a permissions issue or a missing service.

Hyprland relies on seatd or logind (part of systemd) to gain access to the GPU/Input devices without being root. Since seatd failed and logind failed, Hyprland has no permission to draw to the screen, so it crashes.

### The Fix: Grant Seat Permissions

We need to ensure your user (macflow) is in the correct group (seat) and that the seatd service is running.

```bash
# Install seatd (if missing)
sudo pacman -S seatd

# Add user to seat group
sudo usermod -aG seat macflow

# Enable and Start the seatd service
sudo systemctl enable --now seatd

# Reboot
# Group changes require a re-login/reboot to take effect.
sudo reboot
```

## Directory Structure

```text
macFlow/
├── docs/               # Documentation
│   ├── Guest-OS/       # Arch Linux installation and configuration
│   ├── Integration/    # SSH, SSHFS, and Bridge configuration
│   ├── Tools/          # VS Code, git config, etc.
│   ├── VM/             # UTM configuration
│   ├── WM/             # Hyprland and Waybar configuration
│   ├── Desktop.md      # Desktop Mode documentation
│   ├── Headless.md     # Headless Mode documentation
│   ├── Reference.md    # Design philosophy and reference
│   └── Tips.md         # Tips & Tricks
├── ansible/            # IaC: setup.yml, the guest configuration playbook
├── dotfiles/           # Source configuration files (Stow targets)
├── packer/             # IaC: Packer template for automated image builds
├── scripts/            # Installation and setup scripts
├── LICENSE             # Source Code License (MIT)
├── LICENSE-DOCS.md     # Documentation License (CC BY 4.0)
└── README.md           # You are here
```
