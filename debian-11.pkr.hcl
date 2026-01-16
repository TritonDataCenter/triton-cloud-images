/*
 * Debian 11 Packer template for building Triton DataCenter/SmartOS images
 */

/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

/*
 * Copyright 2023 MNX Cloud, Inc.
 */

locals {
  debian_11_ver          = "11.11.0"
  debian_11_iso_url      = "https://cdimage.debian.org/cdimage/archive/${local.debian_11_ver}/amd64/iso-cd/debian-${local.debian_11_ver}-amd64-netinst.iso"
  debian_11_iso_checksum = "file:https://cdimage.debian.org/cdimage/archive/${local.debian_11_ver}/amd64/iso-cd/SHA256SUMS"

  debian_11_boot_command = [
    "<wait><down>e<wait>",
    "<down><down><down><end>",
    "install <wait>",
    "url=${var.base_url}/debian-11.preseed.cfg ",
    "debian-installer=en_US locale=en_US keymap=us ",
    "auto ",
    "efi=runtime ",
    "netcfg/get_hostname=debian11 ",
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

source "bhyve" "debian-11-x86_64" {
  boot_command       = local.debian_11_boot_command
  boot_wait          = var.boot_wait
  cpus               = var.cpus
  disk_size          = var.disk_size
  disk_use_zvol      = var.disk_use_zvol
  disk_zpool         = var.disk_zpool
  host_nic           = var.host_nic
  http_directory     = var.http_directory
  iso_checksum       = local.debian_11_iso_checksum
  iso_url            = local.debian_11_iso_url
  memory             = var.memory
  shutdown_command   = var.root_shutdown_command
  ssh_password       = var.ssh_password
  ssh_timeout        = var.ssh_timeout
  ssh_username       = var.ssh_username
  vm_name            = "debian-11-${formatdate("YYYYMMDD", timestamp())}.x86_64.zfs"
  vnc_bind_address   = var.vnc_bind_address
  vnc_use_password   = var.vnc_use_password
  vnc_port_min       = var.vnc_port_min
  vnc_port_max       = var.vnc_port_max
}

build {
  sources = [
    "bhyve.debian-11-x86_64"
  ]

  # Install ansible and configure locale on the target VM first
  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get install -y ansible locales",
      "sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen",
      "locale-gen",
      "update-locale LANG=en_US.UTF-8"
    ]
  }

  # Run ansible locally on the target VM to avoid illumos multiprocessing issues
  provisioner "ansible-local" {
    playbook_file    = "./ansible/smartos.yml"
    playbook_dir     = "./ansible"
    command          = "LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 ansible-playbook"
  }
}
