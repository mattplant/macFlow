# macFlow: "Headless" Integration with Linux VM

When in "Headless" mode (no GUI), we need to establish reliable integration points between the Host (macOS) and Guest (Linux VM).

- **Files:** Files are shared via **SSHFS**
- **Clipboard:** Copy/Paste is handled thru terminal emulators
- **Identity:** Git credentials are passed via **SSH Agent Forwarding**

For details, see [macFlow: File Integration](./Integration/macFlow-Integration.md).

## Headless Workflow Tips

### Clipboard Sync

When using "Headless" mode, clipboard synchronization relies on your macOS Terminal Emulator (e.g., Terminal.app, iTerm2, Ghostty).

- **Copy (Linux -> Mac):** Highlight text with your mouse. The terminal automatically copies it to the macOS clipboard.
- **Paste (Mac -> Linux):** Use `Cmd+V` as usual. The terminal sends the text as keystrokes to the VM.
- *Pro Tip:* For structured copying (e.g., inside Vim or tmux), ensure your terminal supports OSC 52 escape codes.

### VS Code Remote

For the best experience, use the "Remote - SSH" extension in VS Code on macOS to edit files directly inside the Linux VM.

- Install the "Remote - SSH" extension.
- Click the Remote icon (bottom left) > **Connect to Host...**
- Select `macflow` (It reads your `~/.ssh/config` automatically).
