# macFlow: Automated Image Build (Packer + Ansible)

Infrastructure as Code for `macFlow`. This builds a configured, bootable Arch Linux ARM64 image without stepping through the Archboot installer by hand.

## Strategy

The manual path in [Arch Linux Install](../docs/Guest-OS/Arch-Install.md) is roughly twenty minutes of menu navigation, and every rebuild repeats it. Packer replaces that with one command.

The build runs in two stages, and produces an image that is already configured:

| Stage | Tool | Result |
| :---- | :--- | :----- |
| Base OS | [`scripts/install_base.sh`](./scripts/install_base.sh) | Bootable Arch ARM64, SSH, NetworkManager |
| Configuration | [`ansible/setup.yml`](../ansible/setup.yml) | yay, drivers, services, dotfiles, SSHFS bridge |

Two things are deliberately left out, because each needs a human:

| Step | Tool | Why it is not in the build |
| :--- | :--- | :------------------------- |
| Link the VM to your Mac | [`scripts/connect_mac.sh`](../scripts/connect_mac.sh) | Needs your Mac's hostname, username, and password |
| Desktop Mode *(optional)* | [`scripts/installHyprland.sh`](../scripts/installHyprland.sh) | Not everyone wants a GUI |

## Prerequisites

```bash
# Packer builds the image; QEMU provides the aarch64 emulator and UEFI firmware
brew install packer qemu
```

- **Host:** Apple Silicon Mac. The build uses the Apple Hypervisor framework (`hvf`) for near-native speed.
- **Disk:** ~35 GB free. The image is a 32 GB sparse qcow2, so real usage is far lower, but leave headroom.
- **Time:** Expect a full `pacstrap` download on every build — there is no local package cache.

> *Note:* Ansible is **not** required on macOS. The build uses the `ansible-local`
> provisioner, which installs and runs Ansible inside the guest.

> *Note:* The template hardcodes the Homebrew firmware paths
> (`/opt/homebrew/share/qemu/edk2-aarch64-code.fd` and `edk2-arm-vars.fd`).
> If QEMU is installed elsewhere, update `efi_firmware_code` / `efi_firmware_vars`
> in [`macflow.pkr.hcl`](./macflow.pkr.hcl).

## Build

```bash
cd packer

# Download the QEMU and Ansible plugins declared in the template
# (once per machine)
packer init macflow.pkr.hcl

# Packer refuses to start if the output directory already exists.
rm -rf build_output

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
5. Packer reconnects over SSH as `root`, installs Ansible in the guest, and applies [`ansible/setup.yml`](../ansible/setup.yml).
6. The guest is halted cleanly via `shutdown_command`.

Because step 2 depends on typing into a live console, the boot command is timing
sensitive. If the build hangs, watch the QEMU window and adjust the `<wait…>` values
in the `boot_command` block.

## Provisioning (Ansible)

[`ansible/setup.yml`](../ansible/setup.yml) is the single source of truth for guest
configuration — packages, `yay`, mDNS, services, FUSE, SSH keys, and Stow dotfiles.

It runs in exactly one way, in both install paths: **inside the guest, against
localhost**.

```text
ansible/setup.yml
   |
   +-- Packer build : provisioner "ansible-local"   (packer/macflow.pkr.hcl)
   +-- Manual build : ansible-playbook -c local     (scripts/configArch.sh)
```

Using `ansible-local` rather than the remote `ansible` provisioner is deliberate.
The remote provisioner would run Ansible on macOS and reach into the guest over an
SSH proxy — a second execution model, with its own prerequisites and failure modes,
for the same playbook. Keeping everything guest-side means one model, and nothing
extra to install on the host.

To re-apply the playbook later — after editing dotfiles, say — just run
`scripts/configArch.sh` again. Ansible is idempotent, which the shell script it
replaced was not.

## Using the image

The qcow2 is a raw disk, not a UTM bundle. Create a VM in UTM as described in
[UTM Setup](../docs/VM/UTM.md), then replace its blank drive with this image
(**Settings → Drives**, delete the empty drive, then import `macflow_base.qcow2`
as a VirtIO drive). Apply the same display and network settings the manual path
uses — those are properties of the VM, not of the image.

First login uses the credentials baked in below — change them. The system is
already configured at this point, so the only remaining step is the handshake
with your Mac:

```bash
~/macFlow/scripts/connect_mac.sh
```

## ⚠️ This image ships with known credentials

[`install_base.sh`](./scripts/install_base.sh) sets, and nothing later removes:

| Account | Password | Notes |
| :------ | :------- | :---- |
| `root` | `packer` | Required so Packer can SSH in to verify the build |
| `macflow` | `macflow` | Default user, member of `wheel` |

It also appends `PermitRootLogin yes` to `/etc/ssh/sshd_config`.

**Treat the output as a scratch image on a trusted network.** Change both passwords
and revert `PermitRootLogin` before putting the VM anywhere else.

`scripts/connect_mac.sh` offers to regenerate this VM's SSH *host* keys, which are
otherwise identical in every VM built from the same image. Say yes on a fresh image.

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

- **No cleanup provisioner**, so the build credentials survive into the image. See
  the warning above. This is the obvious next Ansible task.
- **No local package mirror**, so every build re-downloads the base system.
- **`pacman -Sy` before installing Ansible** is a partial-upgrade pattern. It is safe
  here only because `pacstrap` ran moments earlier against the same mirror state.
