/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

/*
 * Copyright 2023 MNX Cloud, Inc.
 */

variables {

  headless              = true
  boot_wait             = "10s"
  cpus                  = 4
  /*
   * disk_zpool must already exist be overridden in the packer command line as
   * `-var disk_zpool=zones/$(zonename)/data/<uuid>`
   */
  disk_zpool            = "zones"
  disk_use_zvol         = true
  memory                = 4096
  post_cpus             = 2
  post_memory           = 2048
  host_nic              = "dhcp0"
  http_directory        = "http"
  base_url              = "http://{{ .HTTPIP }}:{{ .HTTPPort }}"
  ssh_timeout           = "3600s"
  root_shutdown_command = "/sbin/shutdown -hP now"
  qemu_binary           = ""
  #ovmf_code             = "/usr/share/OVMF/OVMF_CODE.secboot.fd"
  ovmf_code             = "/usr/share/ovmf/OVMF.fd"
  ovmf_vars             = "/usr/share/OVMF/OVMF_VARS.ms.fd"
  aavmf_code            = "/usr/share/AAVMF/AAVMF_CODE.fd"

  vnc_bind_address      = "127.0.0.1"
  vnc_use_password      = true
  vnc_port_min          = 5900
  vnc_port_max          = 6000

  disk_size             = "10G"
  ssh_username          = "root"
  ssh_password          = "tritondatacenter"
}
