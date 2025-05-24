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

/*
  iso_url: https://releases.ubuntu.com/noble/ubuntu-24.04.2-live-server-amd64.iso
  iso_checksums: https://releases.ubuntu.com/24.04/SHA256SUMS
*/
variable "proxmox_vm_template" {
  type = map(string)
  default = {
    name             = "ubuntu-24.04-vm"
    descrption       = "Ubuntu 24.04 VM template"
    iso_checksum     = "d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
    iso_file         = "data:iso/ubuntu-24.04.2-live-server-amd64.iso" 
    iso_storage_pool = "data"
    ssh_username     = "ubuntu"
    ssh_key_file     = "~/.ssh/id_ed25519"
    vm_id            = 399
    vm_name          = "noble.home.arpa"
    vm_timezone      = "America/Toronto"
  }
}