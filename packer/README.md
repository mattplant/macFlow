# macFlow: Automated Base Image (Packer)

Infrastructure as Code for `macFlow`. This builds a bootable Arch Linux ARM64 base image without stepping through the Archboot installer by hand.

## Strategy

The manual path in [Arch Linux Install](../docs/Guest-OS/Arch-Install.md) is roughly twenty minutes of menu navigation, and every rebuild repeats it. Packer replaces that with one command.

What Packer does **not** do is build the whole environment. It produces a *base image* only — a minimal, bootable Arch system with networking and SSH. The existing scripts still run on top of it:

| Stage | Tool | Result |
| :---- | :--- | :----- |
| Base OS | `packer build` (this directory) | Bootable Arch ARM64, SSH, NetworkManager |
| Configuration | [`scripts/configArch.sh`](../scripts/configArch.sh) | yay, drivers, dotfiles, SSHFS bridge |
| Desktop *(optional)* | [`scripts/installHyprland.sh`](../scripts/installHyprland.sh) | Hyprland, Waybar, clipboard integration |

## Prerequisites

```bash
# Packer builds the image; QEMU provides the aarch64 emulator and UEFI firmware
brew install packer qemu
```

- **Host:** Apple Silicon Mac. The build uses the Apple Hypervisor framework (`hvf`) for near-native speed.
- **Disk:** ~35 GB free. The image is a 32 GB sparse qcow2, so real usage is far lower, but leave headroom.
- **Time:** Expect a full `pacstrap` download on every build — there is no local package cache.

> *Note:* The template hardcodes the Homebrew firmware paths
> (`/opt/homebrew/share/qemu/edk2-aarch64-code.fd` and `edk2-arm-vars.fd`).
> If QEMU is installed elsewhere, update `efi_firmware_code` / `efi_firmware_vars`
> in [`macflow.pkr.hcl`](./macflow.pkr.hcl).

## Build

```bash
cd packer

# Download the QEMU plugin declared in the template (once per machine)
packer init macflow.pkr.hcl

# Build. A QEMU window opens so you can watch the install happen.
packer build macflow.pkr.hcl
```

Output lands in `packer/build_output/macflow_base.qcow2`. That directory is
git-ignored — the image is multi-GB and must never be committed.

### What the build actually does

Packer boots the Archboot ISO and drives it with keystrokes, rather than using an
answer file (Archboot has no unattended mode):

1. Selects the UEFI boot entry and waits for the live system.
2. Sends `Ctrl+C` to **abort the interactive setup wizard** — the escape hatch that
   gets us to a plain root shell.
3. `curl`s [`scripts/install_base.sh`](./scripts/install_base.sh) from Packer's built-in
   HTTP server (reachable from the guest at `10.0.2.2`) and runs it.
4. `install_base.sh` partitions `/dev/vda`, runs `pacstrap`, configures the system in
   `arch-chroot`, installs systemd-boot, and reboots.
5. Packer reconnects over SSH as `root` to confirm the system came up, then shuts down.

Because step 2 depends on typing into a live console, the boot command is timing
sensitive. If the build hangs, watch the QEMU window and adjust the `<wait…>` values
in the `boot_command` block.

## Using the image

The qcow2 is a raw disk, not a UTM bundle. Create a VM in UTM as described in
[UTM Setup](../docs/VM/UTM.md), then replace its blank drive with this image
(**Settings → Drives**, delete the empty drive, then import `macflow_base.qcow2`
as a VirtIO drive). Apply the same display and network settings the manual path
uses — those are properties of the VM, not of the image.

First login uses the credentials baked in below. Change them, then continue with
[Arch Linux Configuration](../docs/Guest-OS/Arch-Configure.md).

## ⚠️ This image ships with known credentials

[`install_base.sh`](./scripts/install_base.sh) sets, and nothing later removes:

| Account | Password | Notes |
| :------ | :------- | :---- |
| `root` | `packer` | Required so Packer can SSH in to verify the build |
| `macflow` | `macflow` | Default user, member of `wheel` |

It also appends `PermitRootLogin yes` to `/etc/ssh/sshd_config`.

**Treat the output as a scratch image on a trusted network.** Change both passwords
and revert `PermitRootLogin` before putting the VM anywhere else. Hardening this
properly is what the (currently unused) Ansible provisioner is intended for.

## Divergences from the manual install

The Packer image is deliberately simpler than the hand-built system, so a few docs
do not apply to it:

| | Manual ([Arch-Install.md](../docs/Guest-OS/Arch-Install.md)) | Packer |
| :--- | :--- | :--- |
| Root filesystem | Btrfs | **ext4** |
| Bootloader | GRUB | **systemd-boot** |
| Kernel package | `linux` | `linux-aarch64` |

The most visible consequence: the GRUB resolution tuning in
[Desktop.md](../docs/Desktop.md) edits `/etc/default/grub`, which **does not exist**
on a Packer-built image. Use `wlr-randr` or the Hyprland monitor config instead.

## Maintenance

### The ISO URL expires

`iso_url` pins a **dated** Archboot directory rather than `/latest/`, because
Archboot's `latest` folder only ever holds the current build — a dated filename
under it starts returning 404 as soon as a new one ships. Dated directories are
pruned after roughly six months.

When the build fails to download the ISO, pick a current one from
[release.archboot.com/aarch64](https://release.archboot.com/aarch64/) and update
`iso_url`.

`iso_checksum` is `"none"` because Archboot publishes GPG signatures rather than a
`sha256sums` file. Acceptable for a scratch image; verify the signature manually if
that matters to you.

### Known gaps

- **The Ansible plugin is declared but unused.** [`macflow.pkr.hcl`](./macflow.pkr.hcl)
  requires the plugin and the build has no `provisioner` blocks, so configuration
  still happens through the shell scripts. Wiring up Ansible — starting with
  credential cleanup — is the natural next step for #15.
- **No cleanup provisioner.** See the credentials warning above.
- **No local package mirror**, so every build re-downloads the base system.
