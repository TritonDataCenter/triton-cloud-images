
variable "windows_disk_size" {
  type    = string
  default = "25G"
}

variable "iso_url" {
  type    = string
  default = "https://software-static.download.prss.microsoft.com/pr/download/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:549bca46c055157291be6c22a3aaaed8330e78ef4382c99ee82c896426a1cee1"
}

source "bhyve" "windows-2019-x86_64" {
  boot_command       = ["<wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up>"]
  boot_wait          = "8s"
  cpus               = 2
  memory             = 4096
  cd_files           = ["./autounattend.xml", "./triton", "./drivers"]
  disk_size          = var.windows_disk_size

  disk_use_zvol      = var.disk_use_zvol
  disk_zpool         = var.disk_zpool
  host_nic           = var.host_nic

  vnc_bind_address   = var.vnc_bind_address
  vnc_use_password   = false
  vnc_port_min       = var.vnc_port_min
  vnc_port_max       = var.vnc_port_max

  http_directory     = var.http_directory
  iso_url            = var.iso_url
  iso_checksum       = var.iso_checksum
  vm_name            = "windows-2019-${formatdate("YYYYMMDD", timestamp())}.x86_64.zfs"

  communicator       = "none"
  ssh_username       = "root"
  shutdown_command   = ""
  shutdown_timeout   = "1h"
}

build {
  sources = [
    "bhyve.windows-2019-x86_64",
  ]
}
