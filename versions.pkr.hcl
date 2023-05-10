packer {
  required_version = ">= 1.7.0"
  required_plugins {
    bhyve = {
      version = ">= 0.0.0"
      source  = "github.com/TritonDataCenter/bhyve"
    }
    qemu = {
      version = ">= 1.0.7"
      source  = "github.com/hashicorp/qemu"
    }
    ansible = {
      version = ">= 1.0.3"
      source  = "github.com/hashicorp/ansible"
    }
  }
}
