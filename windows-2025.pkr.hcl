variable "windows_2025_disk_size" {
  type    = string
  default = "40G"
}

variable "windows_2025_iso_url" {
  type = string
  # Stable Microsoft redirect: https://go.microsoft.com/fwlink/?linkid=2293312&clcid=0x409&culture=en-us&country=us
  default = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
}

variable "windows_2025_iso_checksum" {
  type    = string
  default = "sha256:d0ef4502e350e3c6c53c15b1b3020d38a5ded011bf04998e950720ac8579b23d"
}

source "bhyve" "windows-2025-x86_64" {
  boot_command       = ["<wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up>"]
  boot_wait          = "2s"
  cpus               = 4
  memory             = 8192
  cd_files           = ["./w2025/autounattend.xml", "./triton", "./drivers"]
  disk_size          = var.windows_2025_disk_size

  disk_use_zvol      = var.disk_use_zvol
  disk_zpool         = var.disk_zpool

  # This runs in a SmartOS non-global zone, where dladm create-vnic is not
  # permitted. communicator = "none" delivers everything over cd_files, so the
  # companion optional-NIC packer-plugin-bhyve patch lets networking stay off.
  host_nic           = ""
  http_directory     = ""

  vnc_bind_address   = var.vnc_bind_address
  vnc_use_password   = false
  vnc_port_min       = var.vnc_port_min
  vnc_port_max       = var.vnc_port_max

  iso_url            = var.windows_2025_iso_url
  iso_checksum       = var.windows_2025_iso_checksum
  vm_name            = "windows-2025-${formatdate("YYYYMMDD", timestamp())}.x86_64.zfs"

  communicator       = "none"
  ssh_username       = "root"
  shutdown_command   = ""
  shutdown_timeout   = "1h"
}

build {
  sources = [
    "bhyve.windows-2025-x86_64",
  ]
}
