/*
 * Debian 12 Packer template for building Triton DataCenter/SmartOS images
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
  debian_12_ver          = "12.9.0"
  debian_12_iso_url      = "https://cdimage.debian.org/debian-cd/${local.debian_12_ver}/amd64/iso-cd/debian-${local.debian_12_ver}-amd64-netinst.iso"
  debian_12_iso_checksum = "file:https://cdimage.debian.org/debian-cd/${local.debian_12_ver}/amd64/iso-cd/SHA256SUMS"

  debian_12_boot_command = [
    "<wait><down>e<wait>",
    "<down><down><down><end>",
    "install <wait>",
    "url=${var.base_url}/debian-12.preseed.cfg ",
    "debian-installer=en_US locale=en_US keymap=us ",
    "auto ",
    "efi=runtime ",
    "netcfg/get_hostname=debian12 ",
    "netcfg/get_domain=tritondatacenter.com ",
    "fb=false debconf/frontend=noninteractive ",
    "passwd/user-fullname=${var.ssh_username} ",
    "passwd/user-password=${var.ssh_password} ",
    "passwd/user-password-again=${var.ssh_password} ",
    "passwd/username=${var.ssh_username} ",
    "console=tty0 console=ttyS0,115200n8 verbose ",
    "tsc=reliable ",
    "<f10><wait>"
  ]

}

source "bhyve" "debian-12-x86_64" {
  boot_command       = local.debian_12_boot_command
  boot_wait          = var.boot_wait
  cpus               = var.cpus
  disk_size          = var.disk_size
  disk_use_zvol      = var.disk_use_zvol
  disk_zpool         = var.disk_zpool
  host_nic           = var.host_nic
  http_directory     = var.http_directory
  iso_checksum       = local.debian_12_iso_checksum
  iso_url            = local.debian_12_iso_url
  memory             = var.memory
  shutdown_command   = var.root_shutdown_command
  ssh_password       = var.ssh_password
  ssh_timeout        = var.ssh_timeout
  ssh_username       = var.ssh_username
  vm_name            = "debian-12-${formatdate("YYYYMMDD", timestamp())}.x86_64.zfs"
  vnc_bind_address   = var.vnc_bind_address
  vnc_use_password   = var.vnc_use_password
  vnc_port_min       = var.vnc_port_min
  vnc_port_max       = var.vnc_port_max
}

build {
  sources = [
    "bhyve.debian-12-x86_64"
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
    ]
  }
}
