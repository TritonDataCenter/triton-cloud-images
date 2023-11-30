 /* FreeBSD 14 Packer template for building Triton DataCenter/SmartOS images
 */

locals {
  freebsd_14_iso_url      = "http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/ISO-IMAGES/14.0/FreeBSD-14.0-RELEASE-amd64-disc1.iso"
  freebsd_14_iso_checksum = "file:http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/ISO-IMAGES/14.0/CHECKSUM.SHA256-FreeBSD-14.0-RELEASE-amd64"

  freebsd_14_boot_command = [
    "<enter>",
    "<wait10><wait10>",
    "s",
    "<wait5>",
    "mdmfs -s 100m md /tmp<enter><wait>",
    "dhclient -p /tmp/dhclient.pid -l /tmp/dhclient.lease vtnet0<enter><wait5>",
    "fetch -o /tmp/installerconfig http://{{ .HTTPIP }}:{{ .HTTPPort }}/freebsd/14/installerconfig<enter><wait>",
    "export FILESYSTEM=\"zfs\"<enter>",
    "export ZFSBOOT_VDEV_TYPE=\"stripe\"<enter>",
    "export ZFSBOOT_DISKS=\"da0\"<enter>",
    "export nonInteractive=\"YES\"<enter>",
    "export BSDINSTALL_DISTSITE=\"https://download.freebsd.org/ftp/releases/amd64/amd64/14.0-RELEASE/\"<enter>",
    "export DISTRIBUTIONS='base.txz kernel.txz'<enter>",
    "bsdinstall script /tmp/installerconfig<enter>",
    "<wait10><wait10><wait10><wait10><wait10><wait10>"
  ]

}

source "bhyve" "freebsd-14-x86_64" {
  boot_command       = local.freebsd_14_boot_command
  boot_wait          = var.boot_wait
  cpus               = var.cpus
  disk_size          = var.disk_size
  disk_use_zvol      = var.disk_use_zvol
  disk_zpool         = var.disk_zpool
  host_nic           = var.host_nic
  http_directory     = var.http_directory
  iso_checksum       = local.freebsd_14_iso_checksum
  iso_url            = local.freebsd_14_iso_url
  memory             = var.memory
  shutdown_command   = "halt -p"
  ssh_password       = var.ssh_password
  ssh_timeout        = var.ssh_timeout
  ssh_username       = var.ssh_username
  vm_name            = "freebsd-14-${formatdate("YYYYMMDD", timestamp())}.x86_64.zfs"
  vnc_bind_address   = var.vnc_bind_address
  vnc_use_password   = var.vnc_use_password
  vnc_port_min       = var.vnc_port_min
  vnc_port_max       = var.vnc_port_max
}

build {
  sources = [
    "bhyve.freebsd-14-x86_64"
  ]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; env {{ .Vars }} {{ .Path }}"
    scripts         = ["scripts/freebsd/14/update.sh", "scripts/freebsd/14/vagrant.sh", "scripts/freebsd/14/zeroconf.sh", "scripts/freebsd/14/ansible.sh", "scripts/freebsd/14/vmtools.sh", "scripts/freebsd/14/cleanup.sh"]
  }
}
