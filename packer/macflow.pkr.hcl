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

source "qemu" "arch_arm" {
  # --- ISO Configuration ---
  # Using Archboot for ARM64.
  # Pin to the DATED archive dir, not /latest/. Archboot's "latest" holds only the
  # current build, so a dated filename under it 404s as soon as a new one ships.
  # Dated dirs persist (~6 months) before being pruned; bump this when it expires.
  iso_url = "https://release.archboot.com/aarch64/2026.08/iso/archboot-2026.08.20-02.07-7.2.0-1-aarch64-ARCH-aarch64.iso"
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

  # Post-Processors (Cleanup) can go here later
}
