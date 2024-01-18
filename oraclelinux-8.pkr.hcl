/*
 * OracleLinux 8 Packer template for building Triton DataCenter/SmartOS images
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
  oraclelinux_8_ver     = "8.9"
  oraclelinux_8_iso_url = "https://yum.oracle.com/ISOS/OracleLinux/OL8/u9/x86_64/x86_64-boot.iso"
  /*oraclelinux_8_iso_checksum = "SHA256(x86_64-boot.iso)= 7ca9cf2b4c28142b0334eeacbd2f2076bf3e7d9bce58f528ceeaa7dde71e6f55"
  */
  oraclelinux_8_iso_checksum = "7ca9cf2b4c28142b0334eeacbd2f2076bf3e7d9bce58f528ceeaa7dde71e6f55"
  oraclelinux_8_boot_command_uefi = [
    "c<wait>",
    "linuxefi /images/pxeboot/vmlinuz inst.repo=cdrom ",
    "inst.text ",
    "inst.nompath ",
    "inst.ks=${var.base_url}/oraclelinux-8.ks<enter>",
    "initrdefi /images/pxeboot/initrd.img<enter>",
    "boot<enter><wait>"
  ]
}

source "bhyve" "oraclelinux-8-x86_64" {
  boot_command       = local.oraclelinux_8_boot_command_uefi
  boot_wait          = var.boot_wait
  cpus               = var.cpus
  disk_size          = var.disk_size
  disk_use_zvol      = var.disk_use_zvol
  disk_zpool         = var.disk_zpool
  host_nic           = var.host_nic
  http_directory     = var.http_directory
  iso_checksum       = local.oraclelinux_8_iso_checksum
  iso_url            = local.oraclelinux_8_iso_url
  memory             = var.memory
  shutdown_command   = var.root_shutdown_command
  ssh_password       = var.ssh_password
  ssh_timeout        = var.ssh_timeout
  ssh_username       = var.ssh_username
  vm_name            = "oraclelinux-8-${formatdate("YYYYMMDD", timestamp())}.x86_64.zfs"
  vnc_bind_address   = var.vnc_bind_address
  vnc_use_password   = var.vnc_use_password
  vnc_port_min       = var.vnc_port_min
  vnc_port_max       = var.vnc_port_max
}

build {
  sources = [
    "bhyve.oraclelinux-8-x86_64"
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
      "ANSIBLE_SSH_ARGS='-o ControlMaster=no -o ControlPersist=180s -o ServerAliveInterval=120s -o TCPKeepAlive=yes -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa'"
    ]
  }
}
