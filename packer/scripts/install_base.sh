#!/bin/bash
set -e

echo "--- STARTING AUTOMATED INSTALL ---"

# Prepare Storage (32GB, GPT, Btrfs)
# Wipe existing signatures
wipefs -a /dev/vda
# Create Partitions: 512M EFI, Rest Root
echo "label: gpt" | sfdisk /dev/vda
echo "start=2048, size=1048576, type=U" | sfdisk /dev/vda --append
echo "start=1050624, type=L" | sfdisk /dev/vda --append
# Format Partitions
# mkfs.fat -F32 -n ESP /dev/vda1
# mkfs.btrfs -L ARCH_ROOT -f /dev/vda2
mkfs.vfat -F32 -n "EFI" /dev/vda1
mkfs.ext4 -L "ROOT" /dev/vda2
# Mount Partitions
# Mount the Root partition FIRST
mount /dev/vda2 /mnt
# Create the mount point for the Boot partition
mkdir -p /mnt/boot
# Mount the EFI partition
mount /dev/vda1 /mnt/boot

# Refresh the package database before installing anything.
#
# The Archboot ISO ships a package database snapshot from the day it was built,
# but mirrors only carry CURRENT package versions. Without this refresh pacstrap
# asks for the versions the snapshot recorded and 404s on anything rebuilt
# since -- which is guaranteed to happen, because we deliberately pin the ISO to
# a completed month for URL stability. This is the trade that makes that safe.
pacman -Sy --noconfirm

# Signing keys rotate too, and a stale keyring makes good packages look corrupt.
# Tolerated if it fails: an out-of-date keyring is not always fatal.
pacman -S --noconfirm --needed archlinuxarm-keyring || true

# Install Base System
pacstrap /mnt base linux-aarch64 linux-firmware \
    mkinitcpio iptables-nft polkit btrfs-progs dosfstools terminus-font \
    openssh nano efibootmgr networkmanager sudo

# Generate Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configure System (Chroot)
arch-chroot /mnt /bin/bash <<EOF

# Time & Locale
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Specify your keyboard layout
echo "KEYMAP=us" > /etc/vconsole.conf

# Network
echo "macflow" > /etc/hostname
echo "127.0.0.1   localhost" >> /etc/hosts
echo "127.0.0.1   macflow.localdomain macflow" >> /etc/hosts

# Initramfs (Kernel Modules for QEMU/UTM Performance)
sed -i 's/^MODULES=()/MODULES=(virtio virtio_pci virtio_blk virtio_net virtio_gpu virtio_balloon virtio_console)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Users
# Root Password (Temporary for Packer SSH)
echo "root:packer" | chpasswd
# User Setup (macflow)
useradd -m -G wheel -s /bin/bash macflow
echo "macflow:macflow" | chpasswd
# Sudoers (Uncomment wheel)
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
# SSH Configuration (Allow Root Login for Packer)
# We need this so Packer can connect immediately after this script finishes to verify the build.
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Bootloader Installation
# Systemd-boot (The Fix)
# Install the bootloader
# This automatically installs to /EFI/BOOT/BOOTAA64.EFI (The magic fallback path)
bootctl --path=/boot install
# Create the Loader Config (Main Menu)
cat <<LOADER > /boot/loader/loader.conf
default arch.conf
timeout 4
console-mode max
editor no
LOADER
# Create the Arch Linux Entry
# Kernel: /Image
# Initrd: /initramfs-linux.img
cat <<ENTRY > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /Image
initrd  /initramfs-linux.img
options root=LABEL=ROOT rw
ENTRY

# Enable Services
systemctl enable NetworkManager
systemctl enable sshd

EOF

# Cleanup
umount -R /mnt
echo "--- INSTALLATION COMPLETE ---"

# REBOOT into the new system
reboot
