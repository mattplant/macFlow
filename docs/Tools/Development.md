# macFlow: Development Tools

Development Tools configuration for the macFlow project.

## VSCode

### Strategy

Options for running VSCode in this architecture:

- **Option A: Hybrid (Recommended for "Headless" Mode)**
  - Install VSCode on **macOS**.
  - Use the **Remote - SSH** extension to connect to `macflow.local`.
  - **Pros:** Native macOS UI/Fonts, maximum battery life, zero latency typing.

- **Option B: VM Native (Recommended for "Desktop" Mode)**
  - Install VSCode inside **Arch Linux**.
  - **Pros:** Full GUI integration with Hyprland workspace rules.

## Installation (VM Native)

Since we have `yay` configured, we can pull the official Microsoft binary directly from the AUR.

```bash
# Install Visual Studio Code (Official Binary)
yay -S visual-studio-code-bin
```

### Configuration: Native Wayland Support

By default, VSCode runs using XWayland. It is stable but might look slightly blurry on HiDPI screens unless you force high scaling.

To force VSCode to run natively on Wayland (sharper text, no X11 overhead), we can create an alias.

```bash
# Edit your shell profile
nano ~/.bash_profile

# Add this alias to force VSCode to use Wayland backend (Ozone)
alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'
```

Reload the profile:

```bash
source ~/.bash_profile
```

*Note:* If you experience flickering or missing window borders, remove the alias to revert to the stable XWayland mode.

### Launch VSCode with Wayland Support

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

# Editor (Set VSCode as default for commit messages)
git config --global core.editor "code --wait"

# Default Branch
git config --global init.defaultBranch main
```

### Generate your SSH key

```bash
# Generate Key (if you haven't already)
ssh-keygen -t ed25519 -C "macflow"
```

### Copy Public Key to GitHub

1) View Key

```bash
cat ~/.ssh/id_ed25519.pub
```

2) Copy the entire output string

3) Go to [GitHub Settings -> SSH Keys](https://github.com/settings/keys)

4) Click `New SSH key` and paste it.

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