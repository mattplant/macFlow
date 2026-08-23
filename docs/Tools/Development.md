# macFlow: Development Tools

Development Tools for the macFlow project.

## VS Code

### Strategy

Options for running VS Code in this architecture:

- **Option A: Hybrid (Recommended for "Headless" Mode)**
  - Install VS Code on **macOS**.
  - Use the **Remote - SSH** extension to connect to `macflow.local`.
  - **Pros:** Native macOS UI/Fonts, maximum battery life, zero latency typing.

- **Option B: VM Native (Recommended for "Desktop" Mode)**
  - Install VS Code inside **Arch Linux**.
  - **Pros:** Full GUI integration with Hyprland workspace rules.

## Installation (VM Native)

Since we have `yay` configured, we can pull the official Microsoft binary directly from the AUR.

```bash
# Install Visual Studio Code (Official Binary)
yay -S visual-studio-code-bin
```

### Configuration: Native Wayland Support

By default, VS Code runs under XWayland. That is stable, but can look slightly blurry
on HiDPI screens.

**This is already configured for you.** The stowed `.bashrc` defines:

```bash
alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'
```

> ⚠️ **Do not edit `~/.bashrc` directly.** After `stow` runs it is a *symlink into this
> repository*, so editing it silently modifies your clone of macFlow. Change
> `dotfiles/shell/.bashrc` in the repo instead, then re-run `configArch.sh` (or
> `stow -R -t ~ shell` from `dotfiles/`) to redeploy.

*Note:* If you hit flickering or missing window borders, remove that alias from
`dotfiles/shell/.bashrc` to fall back to XWayland.

### Launch VS Code with Wayland Support

From the terminal, simply run:

```bash
code
```

## Git Configuration

Set up your Git identity.

```bash
# Identity (Replace with your actual details)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Editor (Set VS Code as default for commit messages)
# Only if VS Code is installed IN the VM. In Headless Mode it runs on macOS, so
# use a terminal editor instead:  git config --global core.editor "nano"
git config --global core.editor "code --wait"

# Default Branch
git config --global init.defaultBranch main
```

### Git Identity: You Probably Do Not Need a Key in the VM

`macFlow` forwards your Mac's SSH agent into the VM, so git inside the VM signs with
the key already on your Mac. Nothing to copy, nothing extra to revoke.

Verify it is working — run this **inside the VM**:

```bash
ssh-add -l
# Your Mac's key fingerprint  -> agent forwarding is working
# "The agent has no identities." -> see docs/Integration/macFlow-Integration.md
```

<details>
<summary>If you specifically want a VM-only key instead</summary>

The playbook already generated one at `~/.ssh/id_ed25519` inside the VM. That key is
what `connect_mac.sh` authorizes on your Mac for SSHFS — it is not registered with
any git host. To use it with GitHub as well:

```bash
# Run this INSIDE the VM
cat ~/.ssh/id_ed25519.pub
```

Copy the output, then add it at
[GitHub Settings → SSH Keys](https://github.com/settings/keys) → `New SSH key`.

Prefer agent forwarding unless you need the VM to authenticate independently of your
Mac — a per-VM key is one more credential to track and revoke.

</details>

## System Information

We use **Fastfetch** as a modern, high-performance replacement for the deprecated `neofetch`. It provides a quick summary of the system hardware and software stack.

```bash
# Install Fastfetch
yay -S fastfetch
```

## Terminal File Manager

Install Yazi and optional dependencies for previews/archives

```bash
yay -S yazi ffmpegthumbnailer unarchiver jq poppler fd ripgrep fzf zoxide imagemagick
```

## Web Browser

### Firefox (Recommended)

We use **Firefox** because it has excellent native Wayland support and performance on ARM64.

```bash
# Install Firefox
yay -S firefox
```

#### Firefox Configuration: Native Wayland Support

Firefox needs `MOZ_ENABLE_WAYLAND=1` to run natively on Wayland instead of XWayland,
giving crisp text and smooth scrolling.

**This is already configured for you**, in the stowed Hyprland config
(`dotfiles/hypr/.config/hypr/conf/monitors.conf`):

```bash
env = MOZ_ENABLE_WAYLAND,1
```

Setting it there rather than in a shell profile means it applies to Firefox launched
from Wofi and keybindings, not just from a terminal. As above, edit the file in the
repo — not the symlink in `~/.config`.

### Chromium (Alternative)

If you strictly need a Blink-based browser for testing:

```bash
yay -S chromium
```
