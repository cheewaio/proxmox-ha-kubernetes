# download ubuntu cloud image
resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = var.ubuntu_cloud_image.storage
  node_name    = var.proxmox.node
  file_name    = var.ubuntu_cloud_image.name
  url          = var.ubuntu_cloud_image.url
  overwrite    = true
}

# download rocky cloud image
resource "proxmox_virtual_environment_download_file" "rocky_cloud_image" {
  content_type       = "iso"
  datastore_id       = var.rocky_cloud_image.storage
  node_name          = var.proxmox.node
  file_name          = var.rocky_cloud_image.name
  url                = var.rocky_cloud_image.url
  overwrite          = true
}

# provision cluster nodes using qemu vm
resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = {
    for k, v in merge(var.control_planes, var.workers) : k => v
  }

  name      = each.key
  vm_id     = each.value.vmid
  node_name = var.proxmox.node
  pool_id   = var.qemu.pool

  cpu {
    type  = var.qemu.cpu_type
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    size         = each.value.disk
    datastore_id = var.qemu.storage
    file_id      = each.value.cloud_image == local.cloud_image.rocky ? proxmox_virtual_environment_download_file.rocky_cloud_image.id : proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    file_format  = "qcow2"
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
  }

  network_device {
    bridge  = var.qemu.bridge
    vlan_id = each.value.vlan
    model   = "virtio"
  }

  initialization {
    datastore_id = var.qemu.storage

    user_account {
      username = each.value.ciuser
      keys     = [file(pathexpand(var.qemu.ssh_public_key_file))]
    }

    ip_config {
      ipv4 {
        address = each.value.cidr
        gateway = each.value.gw
      }
    }

    dns {
      domain = var.qemu.domain
    }
  }

  depends_on = [
    proxmox_virtual_environment_download_file.ubuntu_cloud_image,
    proxmox_virtual_environment_download_file.rocky_cloud_image
  ]
}

# verify VMs are ready by checking SSH connectivity
resource "null_resource" "wait_for_vms" {
  for_each = {
    for k, v in merge(var.control_planes, var.workers) : k => v
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = split("/", each.value.cidr)[0]
      user        = each.value.ciuser
      private_key = file(replace(var.qemu.ssh_public_key_file, ".pub", ""))
    }

    inline = ["echo 'VM ${each.key} is ready'"]
  }

  depends_on = [
    proxmox_virtual_environment_vm.nodes
  ]
}

# generate ansible inventory file
resource "local_file" "qemu_hosts" {
  content = templatefile("${path.module}/templates/hosts.tpl",
    {
      control_planes = var.control_planes
      workers = var.workers
    }
  )
  filename = "../ansible/hosts"

  depends_on = [
    proxmox_virtual_environment_vm.nodes,
    null_resource.wait_for_vms
  ]
}
