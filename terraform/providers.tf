terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.74.1"
    }
  }
}

provider "proxmox" {
  endpoint  = try(local.env["PROXMOX_API_URL"], "")
  api_token = try("${local.env["PROXMOX_API_TOKEN_ID"]}=${local.env["PROXMOX_API_TOKEN_SECRET"]}", "")
  insecure  = var.proxmox.tls_insecure

  ssh {
    agent       = false
    username    = var.proxmox.ssh_username
    private_key = file(var.proxmox.ssh_private_key_file)
  }
}
