locals {
  env = {
    for item in split("\n", file("../../.env")) : split("=", item)[0] => split("=", item)[1] if length(regexall("^\\w+\\s?=", item)) > 0
  }
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "proxmox_pool" {
  type    = string
  default = "kubernetes"
}

variable "proxmox_vm_hardware" {
  type = map(string)
  default = {
    cores           = "2"
    memory          = "2048"
    scsi_controller = "virtio-scsi-pci"
  }
}

variable "proxmox_vm_network" {
  type = map(string)
  default = {
    bridge   = "vmbr1"
    vlan_tag = "30"
  }
}

variable "proxmox_vm_storage" {
  type = map(string)
  default = {
    disk_size = "10G"
    pool      = "local-lvm"
    pool_type = "lvm"
    format    = ""
  }
}

variable "proxmox_vm_template" {
  type = map(string)
  default = {
    name             = "rocky-9-node"
    descrption       = "Rocky Linux 9 template for Kubernetes node"
    iso_checksum     = "file:https://download.rockylinux.org/pub/rocky/9/isos/x86_64/CHECKSUM"
    iso_file         = "data:iso/Rocky-9.0-x86_64-minimal.iso"
    iso_storage_pool = "data"
    iso_url          = "https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9.0-x86_64-minimal.iso"
    ssh_username     = "packer"
    ssh_key_file     = "~/.ssh/id_ed25519"
    vm_id            = 390
    vm_name          = "rocky-blue-onyx"
  }
}
