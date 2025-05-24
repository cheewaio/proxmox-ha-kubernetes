source "proxmox-iso" "rocky" {
  proxmox_url              = try(local.env["PROXMOX_API_URL"], "")
  username                 = try(local.env["PROXMOX_API_TOKEN_ID"], "")
  token                    = try(local.env["PROXMOX_API_TOKEN_SECRET"], "")
  insecure_skip_tls_verify = true

  template_name        = var.proxmox_vm_template.name
  template_description = var.proxmox_vm_template.descrption
  vm_id                = var.proxmox_vm_template.vm_id
  vm_name              = var.proxmox_vm_template.vm_name
  iso_checksum         = var.proxmox_vm_template.iso_checksum
  iso_file             = var.proxmox_vm_template.iso_file
  iso_url              = var.proxmox_vm_template.iso_url
  iso_storage_pool     = var.proxmox_vm_template.iso_storage_pool
  node                 = var.proxmox_node
  pool                 = var.proxmox_pool
  unmount_iso          = true
  qemu_agent           = true
  http_content = {
    "/kickstart.cfg" = templatefile("./templates/kickstart.pkrtpl.hcl", {
      ssh_hostname   = var.proxmox_vm_template.vm_name
      ssh_username   = var.proxmox_vm_template.ssh_username
      ssh_public_key = chomp(file(pathexpand("${var.proxmox_vm_template.ssh_key_file}.pub")))
    })
  }

  cores           = var.proxmox_vm_hardware.cores
  memory          = var.proxmox_vm_hardware.memory
  scsi_controller = var.proxmox_vm_hardware.scsi_controller
  cpu_type        = "host"

  disks {
    type              = "scsi"
    disk_size         = var.proxmox_vm_storage.disk_size
    storage_pool      = var.proxmox_vm_storage.pool
    storage_pool_type = var.proxmox_vm_storage.pool_type
    format            = var.proxmox_vm_storage.format
  }

  network_adapters {
    model    = "virtio"
    bridge   = var.proxmox_vm_network.bridge
    vlan_tag = var.proxmox_vm_network.vlan_tag
    firewall = true
  }

  ssh_username         = var.proxmox_vm_template.ssh_username
  ssh_private_key_file = pathexpand(var.proxmox_vm_template.ssh_key_file)
  ssh_port             = 22
  ssh_timeout          = "15m"

  boot_command = [
    "<tab> text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/kickstart.cfg<enter><wait>"
  ]
}

build {
  sources = ["source.proxmox-iso.rocky"]
}