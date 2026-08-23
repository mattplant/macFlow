packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "iso_url" {
  type        = string
  description = "Archboot aarch64 installer ISO."

  # Archboot keeps exactly ONE build per month directory, and rewrites the
  # CURRENT month's entry as new builds ship -- so a URL inside the current
  # month 404s within days. A PREVIOUS month's directory is frozen and stays
  # valid until pruned, which is roughly six months.
  #
  # So: always pin to a completed month, never the current one or /latest/.
  # When this 404s, pick the newest build from a completed month at
  # https://release.archboot.com/aarch64/ and update this default.
  # Avoid the "-local" and "-latest" filename variants.
  default = "https://release.archboot.com/aarch64/2026.07/iso/archboot-2026.07.29-02.30-7.1.5-2-aarch64-ARCH-aarch64.iso"
}

source "qemu" "arch_arm" {
  # --- ISO Configuration ---
  # Using Archboot for ARM64. Overridable: packer build -var iso_url=...
  iso_url = var.iso_url
  # Archboot publishes only GPG .sig files, no sha256sums, so there is no simple
  # checksum to pin. Acceptable since this is not a production image.
  iso_checksum = "none"

  # --- VM Hardware Specs ---
  # Use Apple Hypervisor framework (hvf) for speed instead of software emulation.
  accelerator = "hvf"
  cpus        = 4
  memory      = 8192

  # Architecture specific settings for Apple Silicon
  qemu_binary  = "qemu-system-aarch64"
  machine_type = "virt"

  # --- UEFI CONFIGURATION (Required for ARM64) ---
  efi_boot = true
  # These paths are standard for Homebrew on Apple Silicon
  efi_firmware_code = "/opt/homebrew/share/qemu/edk2-aarch64-code.fd"
  efi_firmware_vars = "/opt/homebrew/share/qemu/edk2-arm-vars.fd"

  # --- GPU, Input Devices & DisplayU ---
  # "Uncheck Use Apple Virtualization" -> standard QEMU arguments
  qemuargs = [
    ["-cpu", "host"],

    # GPU
    # Using virtio-gpu-pci since hardware OpenGL acceleration (virtio-gpu-gl-pci) causes issues
    ["-device", "virtio-gpu-pci,xres=1920,yres=1080"],

    # USB Controller and Input Devices
    ["-device", "qemu-xhci"],  # eXtensible Host Controller Interface (xHCI) USB 3.0 controller
    ["-device", "usb-kbd"],    # adds a USB keyboard device to the virtual machine
    ["-device", "usb-tablet"], # adds a USB tablet device for mouse input

    # Display
    # Watch the build window on macOS
    # Using "cocoa" since we did not enable OpenGL acceleration ("cocoa,gl=es")
    ["-display", "cocoa"],

    # Force QEMU to show the Guest Display (the VM screen) by disabling the Monitor interface
    ["-monitor", "none"]
  ]

  # --- Disk & Output ---
  disk_size        = "32G"
  format           = "qcow2"
  output_directory = "build_output"
  vm_name          = "macflow_base.qcow2"

  # --- Connection Settings ---
  # Packer connects via SSH *after* the OS is installed to finalize things
  ssh_username = "root"
  ssh_password = "packer" # Must match what we set in install_base.sh
  ssh_timeout  = "20m"

  # Halt the guest cleanly. Without this Packer kills the QEMU process outright,
  # which can leave the ext4 filesystem with a dirty journal on first boot.
  shutdown_command = "shutdown -P now"

  # --- Boot Automation ---
  # This types the keys to get through the Archboot menu
  http_directory = "scripts" # Serves our scripts folder on a local port
  boot_wait      = "5s"
  boot_command = [
    "<enter>",   # Select "Launch UEFI Archboot"
    "<wait18s>", # Wait for boot

    # THE ESCAPE HATCH: Kill the Menu
    # Send Ctrl+C to abort the setup wizard
    "<leftCtrlOn>c<leftCtrlOff>",
    "<wait1s>",

    # Download and Run the Install Script

    # Note: 10.0.2.2 is the special IP that points to your Mac (the host)
    "curl -O http://10.0.2.2:{{ .HTTPPort }}/install_base.sh<enter>",
    # {{ .HTTPIP }} and {{ .HTTPPort }} are auto-filled by Packer
    #"curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/install_base.sh<enter>",

    "chmod +x install_base.sh<enter>",
    "./install_base.sh<enter>"
  ]
}

build {
  sources = ["source.qemu.arch_arm"]

  # --- Provisioning ---
  # We use "ansible-local" rather than the remote "ansible" provisioner, so the
  # playbook runs *inside* the guest against localhost. That is exactly how
  # scripts/configArch.sh applies it on the manual install path, which means
  # both paths share one execution model -- and macOS needs no Ansible install.

  provisioner "shell" {
    inline = [
      "echo '--- Installing Ansible in the guest ---'",
      # -Syu, never -Sy: refreshing the DB without upgrading is a partial
      # upgrade, and installing into it pulls newer libs that file-conflict
      # with the older installed ones. Pulls in Python as a dependency too.
      "pacman -Syu --noconfirm ansible",
    ]
  }

  provisioner "ansible-local" {
    # Resolved relative to this template's directory (packer/).
    playbook_file   = "../ansible/setup.yml"
    extra_arguments = ["--extra-vars", "macflow_user=macflow"]
  }

  # Post-Processors (Cleanup) can go here later
}
