locals {
  env = {
    for item in split("\n", file("../.env")) : split("=", item)[0] => split("=", item)[1] if length(regexall("^\\w+\\s?=", item)) > 0
  }
  cloud_image = {
    ubuntu = "ubuntu-cloud"
    rocky  = "rocky-cloud"
  }
}

variable "proxmox" {
  type = map(string)
  default = {
    node                 = "pve"
    tls_insecure         = true
    ssh_username         = "root"
    ssh_private_key_file = "~/.ssh/id_rsa"
  }
}

variable "ubuntu_cloud_image" {
  type = map(string)
  default = {
    name    = "ubuntu-24.04-server-cloudimg-amd64.img"
    url     = "https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img"
    storage = "data"
  }
}

variable "rocky_cloud_image" {
  type = map(string)
  default = {
    name    = "Rocky-9-GenericCloud-Base.latest.x86_64.qcow2.img"
    url     = "https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
    storage = "data"
  }
}

variable "qemu" {
  type = map(string)
  default = {
    bridge              = "vmbr1"
    cpu_type            = "x86-64-v2-AES"
    onboot              = true
    pool                = "kubernetes"
    ssh_public_key_file = "~/.ssh/id_ed25519.pub"
    storage             = "local-lvm"
    domain              = "home.arpa"
  }
}

variable "control_planes" {
  type = map(map(string))
  default = {
    kube-control-plane-1 = {
      cloud_image = "rocky-cloud"
      ciuser      = "kubeadm"
      cidr        = "192.168.30.11/24"
      cores       = 2
      disk        = "20"
      gw          = "192.168.30.1"
      memory      = 2048
      vlan        = 30
      vmid        = 311
    }
    kube-control-plane-2 = {
      cloud_image = "rocky-cloud"
      ciuser      = "kubeadm"
      cidr        = "192.168.30.12/24"
      cores       = 2
      disk        = "20"
      gw          = "192.168.30.1"
      memory      = 2048
      vlan        = 30
      vmid        = 312
    }
    kube-control-plane-3 = {
      cloud_image = "rocky-cloud"
      ciuser      = "kubeadm"
      cidr        = "192.168.30.13/24"
      cores       = 2
      disk        = "20"
      gw          = "192.168.30.1"
      memory      = 2048
      vlan        = 30
      vmid        = 313
    }
  }
}

variable "workers" {
  type = map(map(string))
  default = {
    kube-worker-1 = {
      cloud_image = "ubuntu-cloud"
      ciuser      = "kubeadm"
      cidr        = "192.168.30.21/24"
      cores       = 4
      disk        = "80"
      gw          = "192.168.30.1"
      memory      = 6144
      vlan        = 30
      vmid        = 321
    }
    kube-worker-2 = {
      cloud_image = "ubuntu-cloud"
      ciuser      = "kubeadm"
      cidr        = "192.168.30.22/24"
      cores       = 4
      disk        = "80"
      gw          = "192.168.30.1"
      memory      = 6144
      vlan        = 30
      vmid        = 322
    }
    kube-worker-3 = {
      cloud_image = "ubuntu-cloud"
      ciuser      = "kubeadm"
      cidr        = "192.168.30.23/24"
      cores       = 4
      disk        = "80"
      gw          = "192.168.30.1"
      memory      = 6144
      vlan        = 30
      vmid        = 323
    }    
  }
}
