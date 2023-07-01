/*
 * Rocky 8 Packer template for building Triton DataCenter/SmartOS images
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
  rocky_8_iso_url      = "https://dl.rockylinux.org/stg/rocky/8.8/isos/x86_64/Rocky-8.8-x86_64-boot.iso"
  rocky_8_iso_checksum = "file:https://dl.rockylinux.org/stg/rocky/8.8/isos/x86_64/CHECKSUM"

  rocky_8_boot_command = [
    "<tab> inst.text net.ifnames=0 inst.gpt inst.ks=${var.kickstart_url}<enter><wait>"
  ]
  rocky_8_boot_command_uefi = [
    "c<wait>",
    "linuxefi /images/pxeboot/vmlinuz inst.repo=cdrom ",
    "inst.text ",
    "inst.nompath ",
    "inst.ks=${var.kickstart_url}<enter>",
    "initrdefi /images/pxeboot/initrd.img<enter>",
    "boot<enter><wait>"
  ]

  rocky_8_kickstart_template = "${path.root}/http/rocky-8.ks"
}

source "bhyve" "rocky-8-smartos-x86_64" {
  boot_command       = local.rocky_8_boot_command_uefi
  boot_wait          = var.boot_wait
  cpus               = var.cpus
  disk_size          = var.disk_size
  disk_use_zvol      = var.disk_use_zvol
  disk_zpool         = var.disk_zpool
  host_nic           = var.host_nic
  http_content       = {
    "/${var.kickstart_file}" = templatefile(local.rocky_8_kickstart_template, {
      disk_device = "vda"
    })
  }
  iso_checksum       = local.rocky_8_iso_checksum
  iso_url            = local.rocky_8_iso_url
  memory             = var.memory
  shutdown_command   = var.root_shutdown_command
  ssh_password       = var.ssh_password
  ssh_timeout        = var.ssh_timeout
  ssh_username       = var.ssh_username
  vm_name            = "rocky-8-smartos-${formatdate("YYYYMMDD", timestamp())}.x86_64.zfs"
  vnc_bind_address   = var.vnc_bind_address
  vnc_use_password   = var.vnc_use_password
  vnc_port_min       = var.vnc_port_min
  vnc_port_max       = var.vnc_port_max
}

build {
  sources = [
    "bhyve.rocky-8-smartos-x86_64"
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
