variables {

  headless              = true
  boot_wait             = "10s"
  cpus                  = 4
  memory                = 4096
  post_cpus             = 2
  post_memory           = 2048
  host_nic              = "net0"
  http_directory        = "http"
  ssh_timeout           = "3600s"
  root_shutdown_command = "/sbin/shutdown -hP now"
  qemu_binary           = ""
  #ovmf_code             = "/usr/share/OVMF/OVMF_CODE.secboot.fd"
  ovmf_code             = "/usr/share/ovmf/OVMF.fd"
  ovmf_vars             = "/usr/share/OVMF/OVMF_VARS.ms.fd"
  aavmf_code            = "/usr/share/AAVMF/AAVMF_CODE.fd"
  vnc_bind_address      = "127.0.0.1"
  vnc_port_min          = 5900
  vnc_port_max          = 6000

  disk_size    = "10G"
  ssh_username = "root"
  ssh_password = "tritondatacenter"

  kickstart_file     = "anaconda.ks"
  kickstart_url      = "http://{{ .HTTPIP }}:{{ .HTTPPort }}/anaconda.ks"
}
