/*
 * Ubuntu 22.04 Packer template for building SmartOS / Triton DataCenter images
 */

locals {
  ubuntu_2204_iso_url      = "https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/jammy-live-server-amd64.iso"
  ubuntu_2204_iso_checksum = "file:https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/SHA256SUMS"

  ubuntu_2204_boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/ubuntu/22.04/\"",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]

}

source "qemu" "ubuntu-2204-smartos-x86_64" {
  iso_url            = local.ubuntu_2204_iso_url
  iso_checksum       = local.ubuntu_2204_iso_checksum
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
  machine_type       = "pc"
  memory             = var.memory
  net_device         = "virtio-net-pci"
  qemu_binary        = var.qemu_binary
  vm_name            = "ubuntu-22.04-smartos-${formatdate("YYYYMMDD", timestamp())}.x86_64.raw"
  boot_wait          = var.boot_wait
  boot_command       = local.ubuntu_2204_boot_command
}

build {
  sources = [
    "qemu.ubuntu-2204-smartos-x86_64",
  ]

  provisioner "ansible" {
    playbook_file    = "./ansible/smartos.yml"
    galaxy_file      = "./ansible/requirements.yml"
    roles_path       = "./ansible/roles"
    collections_path = "./ansible/collections"
    ansible_env_vars = [
      "ANSIBLE_PIPELINING=True",
      "ANSIBLE_REMOTE_TEMP=/tmp",
      "ANSIBLE_SSH_ARGS='-o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa -o ControlMaster=no -o ControlPersist=180s -o ServerAliveInterval=120s -o TCPKeepAlive=yes'",
      "ANSIBLE_HOST_KEY_CHECKING=False"
    ]
    user = "root"
  }
}
