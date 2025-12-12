# macFlow: Development Tools

Development Tools for the macFlow project.

## Stow

TODO: Add in appropriate section

```bash
sudo pacman -S stow
```

## VSCode

### VSCode Strategy

Options for installing VSCode:

- Option A (VM Native): Install code inside Arch. It works, but the UI might feel slightly less "snappy" than macOS native due to the virtualization layer.
- Option B (Hybrid - Recommended): Install VSCode on macOS and use the Remote - SSH extension to connect to your Linux VM.
  - Pros: You get the buttery smooth macOS UI, native battery efficiency, and native fonts/retina rendering, but the terminal, linter, and compiler run inside your Arch VM. This perfectly aligns with your "Host Integrity" goal.

### VSCode Installation

```bash
# Clone the AUR Repo
cd ~
git clone https://aur.archlinux.org/visual-studio-code-bin.git
cd visual-studio-code-bin

# Use the pre-built binary, so it installs very fast
makepkg -si
```

To improve stability and Wayland support, we will add some launch flags to the `code-flags.conf` file.

```bash
mkdir -p ~/.config
nano ~/.config/code-flags.conf
```

Add these lines to the file:

```text
--enable-features=UseOzonePlatform
--ozone-platform=wayland
--disable-gpu
```

### Launch VSCode with Wayland Support

When launching VSCode from the terminal, use this command to ensure it uses the Wayland backend:

```bash
code
```
