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

By default, VS Code runs using XWayland. It is stable but might look slightly blurry on HiDPI screens unless you force high scaling.

To force VS Code to run natively on Wayland (sharper text, no X11 overhead), we can create an alias.

```bash
# Edit your shell profile
nano ~/.bash_profile

# Add this alias to force VS Code to use Wayland backend (Ozone)
alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'
```

Reload the profile:

```bash
source ~/.bash_profile
```

*Note:* If you experience flickering or missing window borders, remove the alias to revert to the stable XWayland mode.

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
git config --global core.editor "code --wait"

# Default Branch
git config --global init.defaultBranch main
```

### Copy Public Key to GitHub

1) View Key

```bash
cat ~/.ssh/id_ed25519.pub
```

2) Copy the entire output string

3) Go to [GitHub Settings -> SSH Keys](https://github.com/settings/keys)

4) Click `New SSH key` and paste it.

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

To ensure Firefox runs natively on Wayland (instead of XWayland) for crisp text and smooth scrolling, we set an environment variable.

```bash
nano ~/.bash_profile
# Add/Verify this line exists to force Firefox to use Wayland backend
export MOZ_ENABLE_WAYLAND=1

Reload the profile:

```bash
source ~/.bash_profile
```

### Chromium (Alternative)

If you strictly need a Blink-based browser for testing:

```bash
yay -S chromium
```
