# macFlow: Arch Linux Installation

Build notes for installing **Arch Linux ARM (ALARM)** using [UTM](../VM/UTM.md) on macOS.

## Initial Boot

- **Start the VM** (Play button).

## Core Installation (Archboot)

- From the `GNU Grub` menu in the **Serial Console** window:
  - Select `Launch UEFI Archboot - Arch Linux aarch64`
- From the **Archboot** menu:
  - Press `ENTER` to log in as root and start setup
    - **Locale:** Select `en-US`
    - **Network Interface:** Select `enp0s1`
    - **Network Profile Name:** Accept default ('enp0s1-ethernet')
      - *Note:* This sets the `Network profile` to `/etc/systemd/network/enp0s1-ethernet.network`
    - **Network Configuration:** Select `DHCP`
    - **Proxy Configuration:** Leave blank
  - On `Summary` screen, review settings and select `Yes` to apply.
  - Select a local mirror when prompted.

### Partitioning (Quick Setup)

- From the **Launcher Menu**, select **`Launch Archboot Setup`**
  - Select **`Prepare Storage Device`** > **`Quick Setup`**
    - For the size of the disk, enter `32G` *(32 GB)*
      - *Note:* UTM uses a VirtIO disk that appears as `/dev/vda`
    - **Device Name Scheme:** `FSUUID` *(Industry standard for persistent block device naming)*
    - **EFI System Partition (ESP):** `/boot (single boot)`
      - **EFI Size:** `512` *(512 MB)*
      - **Swap:** `0` *(We do not use swap)*
      - **File System:** Select `Btrfs` (Confirm with `Yes`)
      - **Root Size:** `0` *(Uses remaining space)* (Confirm with `Yes`)
      - Confirm wipe and partition of "/dev/vda" by selecting `Yes`

### Package Selection

From the **Setup Menu**, select **`Install Packages`**

- Confirm installation of these required packages for minimum system by selecting `Yes`
  - `base` - core OS
  - `iptables-nft` - firewall utilities
  - `linux` - Linux kernel
  - `polkit` - privilege management
  - `btrfs-progs` - BTRFS filesystem tools
  - `dosfstools` - DOS filesystem utilities
  - `terminal-fonts` - console fonts

### Configuration

From the **Setup Menu**, select **`Configure System`**

- **Root Password:** Set root password
- **Default Editor:** Select `Nano` (easy for beginners) or `NEOVIM` (experts)
  - **Note:** In this guide, we will use `Nano` to edit files to keep things simple and accessible.
- **Init System:** Select `SYSTEMD`
- From the **System Configuration** menu:
  - From the **User Management** menu:
    - **Default Shell:** Select `bash`
    - **Create User Account**, enter `macflow`
      - Select `Enable macflow as Admistrator and part of wheel group`
      - For comment, enter `macFlow is awesome` or your full name :)
      - Enter and confirm user password
      - Return to `System Configuration`
  - Go thru all the other **System Configuration** options and accept defaults except where called out below:
    - Set **System Hostname** to `macflow`
    - For **Network Hosts** (/etc/hosts) add this entry to bottom `127.0.0.1        macflow.localdomain macflow`
    - Return to `Main Menu`
      - Select `Return to System Configuration`
    - Go thru each `System Configuration` option and accept defaults except where called out below:
      - For **Kernel Modules** add these: `virtio virtio_pci virtio_blk virtio_net virtio_gpu virtio_balloon virtio_console`
        - *Why?* These modules provide optimal performance and compatibility with UTM's virtualized hardware.
      - Set **System Hostname** to `macflow`
      - For **Network Hosts** (/etc/hosts) add this entry to bottom `127.0.0.1        macflow.localdomain macflow`
      - Return to `Main Menu`

### Install Bootloader

- Select `Install Bootloader` from the Archboot **Setup Menu**
  - For `AA64 UEFI Bootloader` select `GRUB_UEFI`
    - *Why?* Safer recovery method, easy confiig format and snapshot (future proofing)

### Finish Installation

- From the **Setup Menu**, select **`Exit` > `Poweroff System`
  - *Why?* This provides a clean stop, allowing you to eject the ISO from VMware settings so your first boot actually goes to your new Arch Linux hard drive.`
- Prevent the VM from booting back into the Archboot ISO:
  - On the `macFlow` VM in UTM, clear the image from the `CD/DVD`.

## Continue to Arch Linux Configuration

Follow the steps in [Arch Linux Configuration](../Guest-OS/Arch-Configure.md) to configure Arch Linux for macFlow.
