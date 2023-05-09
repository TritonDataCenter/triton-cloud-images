/*
 * RockyLinux OS 8 Packer template for building Triton DataCenter/SmartOS images
 */

locals {
  rocky_8_iso_url      = "https://dl.rockylinux.org/stg/rocky/8.8/isos/x86_64/Rocky-8.8-x86_64-boot.iso"
  rocky_8_iso_checksum = "file:https://dl.rockylinux.org/stg/rocky/8.8/isos/x86_64/CHECKSUM"

  rocky_8_boot_command = [
    "<tab> inst.text net.ifnames=0 inst.gpt inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/rocky-8.smartos-x86_64.ks<enter><wait>"
  ]
  rocky_8_boot_command_uefi = [
    "c<wait>",
    "linuxefi /images/pxeboot/vmlinuz inst.repo=cdrom ",
    "inst.text ",
    "inst.nompath ",
    "inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/rocky-8.smartos-x86_64.ks<enter>",
    "initrdefi /images/pxeboot/initrd.img<enter>",
    "boot<enter><wait>"
  ]
}

source "bhyve" "rocky-8-smartos-x86_64" {
  boot_command       = local.rocky_8_boot_command_uefi
  boot_wait          = var.boot_wait
  cpus               = var.cpus
  disk_size          = var.disk_size
  http_directory     = var.http_directory
  iso_checksum       = local.rocky_8_iso_checksum
  iso_url            = local.rocky_8_iso_url
  memory             = var.memory
  shutdown_command   = var.root_shutdown_command
  ssh_password       = var.ssh_password
  ssh_timeout        = var.ssh_timeout
  ssh_username       = var.ssh_username
  vm_name            = "rocky-8.7-smartos-${formatdate("YYYYMMDD", timestamp())}.x86_64.raw"
}

source "qemu" "rocky-8-smartos-x86_64" {
  iso_url            = local.rocky_8_iso_url
  iso_checksum       = local.rocky_8_iso_checksum
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
  memory             = var.memory
  net_device         = "virtio-net"
  qemu_binary        = var.qemu_binary
  vm_name            = "rocky-8.8-smartos-${formatdate("YYYYMMDD", timestamp())}.x86_64.raw"
  boot_wait          = var.boot_wait
  boot_command       = local.rocky_8_boot_command
}

source "qemu" "rocky-8-smartos-uefi-x86_64" {
  iso_url            = local.rocky_8_iso_url
  iso_checksum       = local.rocky_8_iso_checksum
  shutdown_command   = var.root_shutdown_command
  accelerator        = "kvm"
  http_directory     = var.http_directory
  ssh_username       = var.ssh_username
  ssh_password       = var.ssh_password
  ssh_timeout        = var.ssh_timeout
  cpus               = var.cpus
  efi_firmware_code  = var.ovmf_code
  efi_firmware_vars  = var.ovmf_vars
  disk_interface     = "virtio-scsi"
  disk_size          = var.disk_size
  disk_cache         = "unsafe"
  disk_discard       = "unmap"
  disk_detect_zeroes = "unmap"
  disk_compression   = true
  format             = "raw"
  headless           = var.headless
  machine_type       = "q35"
  memory             = var.memory
  net_device         = "virtio-net"
  qemu_binary        = var.qemu_binary
  vm_name            = "rocky-8.8-smartos-uefi-${formatdate("YYYYMMDD", timestamp())}.x86_64.raw"
  boot_wait          = var.boot_wait
  boot_command       = local.rocky_8_boot_command_uefi
}

build {
  sources = [
    "bhyve.rocky-8-smartos-x86_64",
    "qemu.rocky-8-smartos-uefi-x86_64"
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
