source "proxmox-iso" "ubuntu" {
  proxmox_url              = try("${local.env["PROXMOX_API_URL"]}/api2/json", "")
  username                 = try(local.env["PROXMOX_API_TOKEN_ID"], "")
  token                    = try(local.env["PROXMOX_API_TOKEN_SECRET"], "")
  insecure_skip_tls_verify = true

  template_name        = var.proxmox_vm_template.name
  template_description = var.proxmox_vm_template.descrption
  vm_id                = var.proxmox_vm_template.vm_id
  vm_name              = var.proxmox_vm_template.vm_name

  boot_iso {
    type             = "scsi"
    iso_checksum     = var.proxmox_vm_template.iso_checksum
    iso_file         = var.proxmox_vm_template.iso_file
    iso_storage_pool = var.proxmox_vm_template.iso_storage_pool
    unmount          = true
  }

  node       = var.proxmox_node
  pool       = var.proxmox_pool
  qemu_agent = true
  http_content = {
    "/meta-data" = ""
    "/user-data" = templatefile("./templates/user-data.pkrtpl.hcl", {
      ssh_hostname   = var.proxmox_vm_template.vm_name
      ssh_username   = var.proxmox_vm_template.ssh_username
      ssh_public_key = chomp(file(pathexpand("${var.proxmox_vm_template.ssh_key_file}.pub")))
      vm_timezone    = var.proxmox_vm_template.vm_timezone
    })
  }

  cores           = var.proxmox_vm_hardware.cores
  memory          = var.proxmox_vm_hardware.memory
  scsi_controller = var.proxmox_vm_hardware.scsi_controller

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

  boot_wait = "10s"
  boot_command = [
    "c",
    "linux /casper/vmlinuz --- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'",
    "<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]
}

build {
  sources = ["source.proxmox-iso.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo find /etc/cloud/cloud.cfg.d -type f -not -name '05_logging.cfg' -not -name '90_dpkg.cfg' -exec rm -f {} \\;",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id"
    ]
  }
}