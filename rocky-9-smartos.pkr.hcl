/*
 * Rocky 9 Packer template for building Triton DataCenter/SmartOS images
 */

locals {
  rocky_9_iso_url      = "https://dl.rockylinux.org/stg/rocky/9.1/isos/x86_64/Rocky-9.1-x86_64-boot.iso"
  rocky_9_iso_checksum = "file:https://dl.rockylinux.org/stg/rocky/9.1/isos/x86_64/CHECKSUM"

  rocky_9_boot_command = [
    "<tab> inst.text biosdevname=0 net.ifnames=0 inst.gpt inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/rocky-9.smartos-x86_64.ks<enter><wait>"
  ]

  rocky_9_boot_command_uefi = [
    "c<wait>",
    "linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=Rocky-9-1-x86_64-dvd ro ",
    "inst.text biosdevname=0 net.ifnames=0 ",
    "inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/rocky-9.smartos-x86_64.ks<enter>",
    "initrdefi /images/pxeboot/initrd.img<enter>",
    "boot<enter><wait>"
  ]



}


source "qemu" "rocky-9-smartos-x86_64" {
  iso_url            = local.rocky_9_iso_url
  iso_checksum       = local.rocky_9_iso_checksum
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
  vm_name            = "rocky-9.1-smartos-${formatdate("YYYYMMDD", timestamp())}.x86_64.raw"
  boot_wait          = var.boot_wait
  boot_command       = local.rocky_9_boot_command
  qemuargs = [
    ["-cpu", "host"]
  ]
}

source "qemu" "rocky-9-smartos-uefi-x86_64" {
  iso_url            = local.rocky_9_iso_url
  iso_checksum       = local.rocky_9_iso_checksum
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
  machine_type       = "ubuntu-q35"
  memory             = var.memory
  net_device         = "virtio-net"
  qemu_binary        = var.qemu_binary
  vm_name            = "rocky-9.1-smartos-${formatdate("YYYYMMDD", timestamp())}.x86_64.raw"
  boot_wait          = var.boot_wait
  boot_command       = local.rocky_9_boot_command_uefi
  qemuargs = [
    ["-cpu", "host"]
  ]
}

build {
  sources = [
    "qemu.rocky-9-smartos-uefi-x86_64"
  ]

  provisioner "ansible" {
    playbook_file    = "./ansible/smartos.yml"
    galaxy_file      = "./ansible/requirements.yml"
    roles_path       = "./ansible/roles"
    collections_path = "./ansible/collections"
    ansible_env_vars = [
      "ANSIBLE_PIPELINING=True",
      "ANSIBLE_REMOTE_TEMP=/tmp",
      "ANSIBLE_SSH_ARGS='-o ControlMaster=no -o ControlPersist=180s -o ServerAliveInterval=120s -o TCPKeepAlive=yes'"
    ]
  }
}
