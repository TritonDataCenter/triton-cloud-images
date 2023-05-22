/*
 * AlmaLinux OS 9 Packer template for building Triton DataCenter/SmartOS images
 */

locals {
  almalinux_9_iso_url      = "https://repo.almalinux.org/almalinux/9.2/isos/x86_64/AlmaLinux-9.2-x86_64-boot.iso"
  almalinux_9_iso_checksum = "file:https://repo.almalinux.org/almalinux/9.2/isos/x86_64/CHECKSUM"

  almalinux_9_boot_command = [
    "<tab> inst.text biosdevname=0 net.ifnames=0 inst.gpt inst.ks=${var.kickstart_url}<enter><wait>"
  ]
  almalinux_9_boot_command_uefi = [
    "c<wait>",
    "linuxefi /images/pxeboot/vmlinuz inst.repo=cdrom ",
    "inst.text biosdevname=0 net.ifnames=0 ",
    "inst.ks=${var.kickstart_url}<enter>",
    "initrdefi /images/pxeboot/initrd.img<enter>",
    "boot<enter><wait>"
  ]

  almalinux_9_kickstart_template = "${path.root}/http/almalinux-9.smartos-x86_64.ks"
}

source "bhyve" "almalinux-9-smartos-x86_64" {
  boot_command       = local.almalinux_9_boot_command_uefi
  boot_wait          = var.boot_wait
  cpus               = var.cpus
  disk_size          = var.disk_size
  disk_use_zvol      = var.disk_use_zvol
  disk_zpool         = var.disk_zpool
  host_nic           = var.host_nic
  http_content       = {
    "/${var.kickstart_file}" = templatefile(local.almalinux_9_kickstart_template, {
      disk_device = "vda"
    })
  }
  iso_checksum       = local.almalinux_9_iso_checksum
  iso_url            = local.almalinux_9_iso_url
  memory             = var.memory
  shutdown_command   = var.root_shutdown_command
  ssh_password       = var.ssh_password
  ssh_timeout        = var.ssh_timeout
  ssh_username       = var.ssh_username
  vm_name            = "almalinux-9.2-smartos-${formatdate("YYYYMMDD", timestamp())}.x86_64.raw"
  vnc_bind_address   = var.vnc_bind_address
  vnc_use_password   = true
}

source "qemu" "almalinux-9-smartos-x86_64" {
  iso_url            = local.almalinux_9_iso_url
  iso_checksum       = local.almalinux_9_iso_checksum
  shutdown_command   = var.root_shutdown_command
  accelerator        = "kvm"
  http_directory     = var.http_directory
  ssh_username       = var.ssh_username
  ssh_password       = var.ssh_password
  ssh_timeout        = var.ssh_timeout
  cpus               = var.cpus
  disk_interface     = "virtio-scsi"
  disk_size          = var.disk_size
  disk_cache         = "unsafe"
  disk_discard       = "unmap"
  disk_detect_zeroes = "unmap"
  disk_compression   = true
  format             = "raw"
  headless           = var.headless
  machine_type       = "ubuntu-q35"
  memory             = var.memory
  net_device         = "virtio-net"
  qemu_binary        = var.qemu_binary
  vm_name            = "almalinux-9.2-smartos-${formatdate("YYYYMMDD", timestamp())}.x86_64.raw"
  boot_wait          = var.boot_wait
  boot_command       = local.almalinux_9_boot_command
  qemuargs = [
    ["-cpu", "host"]
  ]
}

source "qemu" "almalinux-9-smartos-uefi-x86_64" {
  iso_url            = local.almalinux_9_iso_url
  iso_checksum       = local.almalinux_9_iso_checksum
  shutdown_command   = var.root_shutdown_command
  accelerator        = "kvm"
  http_directory     = var.http_directory
  ssh_username       = var.ssh_username
  ssh_password       = var.ssh_password
  ssh_timeout        = var.ssh_timeout
  cpus               = var.cpus
  efi_firmware_code  = var.ovmf_code
  efi_firmware_vars  = var.ovmf_vars
  firmware           = var.ovmf_code
  disk_interface     = "virtio-scsi"
  disk_size          = var.disk_size
  disk_cache         = "unsafe"
  disk_discard       = "unmap"
  disk_detect_zeroes = "unmap"
  disk_compression   = true
  format             = "raw"
  headless           = var.headless
  machine_type       = "ubuntu-q35"
  memory             = var.memory
  net_device         = "virtio-net"
  qemu_binary        = var.qemu_binary
  vm_name            = "almalinux-9.2-smartos-${formatdate("YYYYMMDD", timestamp())}.x86_64.raw"
  boot_wait          = var.boot_wait
  boot_command       = local.almalinux_9_boot_command_uefi
  qemuargs = [
    ["-cpu", "host"]
  ]
}

build {
  sources = [
    "bhyve.almalinux-9-smartos-x86_64",
    "qemu.almalinux-9-smartos-uefi-x86_64",
    "qemu.almalinux-9-smartos-x86_64"
  ]

  provisioner "ansible" {
    playbook_file    = "./ansible/smartos.yml"
    galaxy_file      = "./ansible/requirements.yml"
    roles_path       = "./ansible/roles"
    collections_path = "./ansible/collections"
    extra_arguments  = [ "--scp-extra-args", "'-O'" ]
    ansible_env_vars = [
      "ANSIBLE_PIPELINING=True",
      "ANSIBLE_REMOTE_TEMP=/tmp",
      "ANSIBLE_SSH_ARGS='-o ControlMaster=no -o ControlPersist=180s -o ServerAliveInterval=120s -o TCPKeepAlive=yes -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa'"
    ]
  }
}
