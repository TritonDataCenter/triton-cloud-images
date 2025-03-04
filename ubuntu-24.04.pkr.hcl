/*
 * Ubuntu 24.04 Packer template for building SmartOS / Triton DataCenter images
 */

/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

/*
 * Copyright 2025 MNX Cloud, Inc.
 */

locals {
  ubuntu_24_ver          = "24.04.2"
  ubuntu_24_iso_url      = "https://releases.ubuntu.com/noble/ubuntu-${local.ubuntu_24_ver}-live-server-amd64.iso"
  ubuntu_24_iso_checksum = "file:https://releases.ubuntu.com/noble/SHA256SUMS"

  ubuntu_24_boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall console=tty0 console=ttyS0,115200n8 ds=\"nocloud-net;seedfrom=${var.base_url}/ubuntu/24.04/\"",
    " tsc=reliable",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]

}

source "bhyve" "ubuntu-2404-x86_64" {
  boot_command       = local.ubuntu_24_boot_command
  boot_wait          = var.boot_wait
  cpus               = var.cpus
  disk_size          = var.disk_size
  disk_use_zvol      = var.disk_use_zvol
  disk_zpool         = var.disk_zpool
  host_nic           = var.host_nic
  http_directory     = var.http_directory
  iso_checksum       = local.ubuntu_24_iso_checksum
  iso_url            = local.ubuntu_24_iso_url
  memory             = var.memory
  shutdown_command   = var.root_shutdown_command
  ssh_password       = var.ssh_password
  ssh_timeout        = var.ssh_timeout
  ssh_username       = var.ssh_username
  vm_name            = "ubuntu-24.04-${formatdate("YYYYMMDD", timestamp())}.x86_64.zfs"
  vnc_bind_address   = var.vnc_bind_address
  vnc_use_password   = var.vnc_use_password
  vnc_port_min       = var.vnc_port_min
  vnc_port_max       = var.vnc_port_max
}

build {
  sources = [
    "bhyve.ubuntu-2404-x86_64"
  ]

  provisioner "ansible" {
    playbook_file    = "./ansible/smartos.yml"
    galaxy_file      = "./ansible/requirements.yml"
    roles_path       = "./ansible/roles"
    collections_path = "./ansible/collections"
    extra_arguments  = [ "--scp-extra-args", "'-O '" ]
    ansible_env_vars = [
      "ANSIBLE_PIPELINING=True",
      "ANSIBLE_REMOTE_TEMP=/tmp",
      "ANSIBLE_SSH_ARGS='-o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa -o ControlMaster=no -o ControlPersist=180s -o ServerAliveInterval=120s -o TCPKeepAlive=yes'",
      "ANSIBLE_HOST_KEY_CHECKING=False"
    ]
    user = "root"
  }
}
