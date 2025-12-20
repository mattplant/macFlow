# macFlow: Arch Linux (ARM) Installation

Build notes for installing **Arch Linux ARM (ALARM)** using [UTM](../VM/UTM.md) on macOS.

## Initial Boot

- **Start the VM** (Play button).

## Core Installation (Archboot)

- From the `GNU Grub` menu in the **Serial Console** window:
  - Select `Launch UEFI Archboot - Arch Linux aarch64`
- From the **Archboot** menu:
  - Press `ENTER` to log in as root and start setup
    - **Locale:** Select `en-US English`
    - **Network Interface:** Select `enp0s1`
    - **Network Profile Name:** Accept default ('enp0s1-ethernet')
      - *Note:* This sets the `Network profile` to `/etc/systemd/network/enp0s1-ethernet.network`
    - **Network Configuration:** Select `DHCP`
    - **Proxy Configuration:** Leave blank
  - On `Summary` screen, review settings and select `Yes` to apply.
  - Select a local mirror when prompted.

### Partitioning (Quick Setup)

- From the **Launcher** menu, select **`Launch Archboot Setup`**
  - Select **`Prepare Storage Device`** > **`Quick Setup`**
    - For the size of the disk, enter `40G` *(40 GB)*
      - *Note:* UTM uses a VirtIO disk that appears as `/dev/vda`
    - **Device Name Scheme:** `FSUUID` *(Industry standard for persistent block device naming)*
    - **EFI System Partition (ESP):** `/boot (single boot)`
      - **EFI Size:** `1024` *(1 GB)*
      - **Swap:** `0` *(We do not use swap)*
      - **File System:** Select `Btrfs` (Confirm with `Yes`)
      - **Root Size:** `0` *(Uses remaining space)* (Confirm with `Yes`)
      - Confirm wipe and partition of "/dev/vda" by selecting `Yes`

### Package Selection

From the **Launcher** menu, select **`Install Packages`**

- Confirm installation of these required packages for minimum system by selecting `Yes`
  - `base` - core OS
  - `iptables-nft` - firewall utilities
  - `linux` - Linux kernel
  - `polkit` - privilege management
  - `btrfs-progs` - BTRFS filesystem tools
  - `dosfstools` - DOS filesystem utilities
  - `terminal-fonts` - console fonts

### Configuration

From the **Launcher** menu, select **`Configure System`**

- **Root Password:** Set root password
- **Default Editor:** Select `Nano` (easy for beginners or whatever you prefer)
- **Init System:** Select `systemd` (mkinitcpio will be configured automatically)
- From the **System Configuration**` menu:
  - From the **User Management** menu:
    - **Default Shell:** Select `bash`
    - **Create User Account**, enter `macflow`
      - Add to `wheel` group for sudo access
      - For comment, enter `macFlow is awesome` or your full name :)
      - Enter and confirm user password
      - Return to `System Configuration`
    - Go thru each system config option and accept defaults except where called out below:
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
  - On the `macFlow` VM in UTM, clear the image from the `CD/DVD`

## Continue to Arch Linux Configuration

Follow the steps in [Arch Linux Configuration](../Guest-OS/Arch-Configure.md) to configure Arch Linux for macFlow.
