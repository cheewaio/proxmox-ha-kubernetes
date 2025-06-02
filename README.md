# Proxmox High Availability Kubernetes

This repository contains Infrastructure as Code (IaC) to deploy a High Availability Kubernetes cluster on Proxmox VE using Terraform, Packer and Ansible.

## Prerequisites

- Proxmox VE server
- Proxmox API token with appropriate permissions
- SSH key pair for VM access
- Tools installed on your workstation:
  - Terraform
  - Packer 
  - Ansible
  - Make

## Configuration

1. Create a `.env` file from the example:

```bash
cp .env.example .env
```

2. Configure the required environment variables:

```bash
PROXMOX_API_URL=https://proxmox.example.com:8006
PROXMOX_API_TOKEN_ID=your-token-id
PROXMOX_API_TOKEN_SECRET=your-token-secret
```

3. Since GitHub imposes rate limit for anonymous access, it is highly recommended to setup a personal access token.

```bash
GITHUB_ACCESS_TOKEN=your-personal-token
```

## Usage

The project uses a Makefile to orchestrate the deployment process:

### Build VM Templates (Optional)

Build base VM templates in Proxmox. It's only needed if you prefer to build your own cloud image.

```bash
# Build Rocky Linux template
make rocky

# Build Ubuntu template 
make ubuntu
```

### Deploy Kubernetes Cluster

1. Configure the cluster settings:

Edit `terraform/variables.tf` to customize the VM configurations:
```hcl
variable "control_plane_count" { default = 3 }     # Number of control plane nodes
variable "worker_node_count" { default = 2 }       # Number of worker nodes
variable "control_plane_memory" { default = 2048 } # Memory in MB
variable "worker_node_memory" { default = 6144 }   # Memory in MB
```

Edit `ansible/group_vars/all.yml` to configure Kubernetes settings:
```yaml
# Kubernetes Settings
kubernetes_version: "1.32.0"         # Kubernetes version
container_runtime: "containerd"      # Container runtime (containerd/cri-o)
cni_plugin: "cilium"                 # CNI plugin (calico/cilium/flannel)
pod_cidr: "10.244.0.0/16"            # Pod network CIDR
service_cidr: "10.96.0.0/12"         # Service network CIDR
```

Edit `ansible/group_vars/control-planes.yml` to configure control-planes settings:
```yaml
# Control Planes Settings
kube_vip_enabled: true               # Enable kube-vip for control plane HA
kube_vip_interface: eth0             # Network interface for kube-vip
kube_vip_address: 192.168.30.100     # Virtual IP address for control plane
kube_vip_loadbalancer_ip_range: 192.168.30.200-192.168.30.220  # Load balancer IP range
```

Edit `ansible/group_vars/workers.yml` to configure workers settings:
```yaml
# Workers Settings
csi_pugin: "longhorn"                # CSI plugin (longhorn)
```

2. Create the VMs:

```bash
make nodes
```

This will:
- Download cloud images
- Create VMs using Terraform
- Configure networking
- Generate Ansible inventory

3. Install and configure Kubernetes:

```bash
make cluster
```

This will:
- Install container runtime (containerd/cri-o)
- Setup Kubernetes components
- Initialize control plane
- Join worker nodes
- Deploy CNI plugin (Calico/Cilium/Flannel)
- Deploy MetalLB for load balancing
- Configure ingress controller

### Upgrade Kubernetes Cluster

To upgrade the Kubernetes cluster to a newer version:

1. Update the Kubernetes version in `ansible/group_vars/all.yml`:
```yaml
kubernetes_version: "1.33.0"  # Set to desired version
```

2. Run the upgrade playbook:
```bash
make cluster-upgrade
```

This will:
- Upgrade control plane components one node at a time
- Drain and upgrade worker nodes sequentially
- Update CNI and other cluster addons
- Verify cluster health after upgrade

> **Note**: It's recommended to:
> - Review the [official upgrade notes](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/) for your target version
> - Backup etcd data before upgrading
> - Upgrade only one minor version at a time (e.g., 1.32.x → 1.33.x)

### Clean Up

To destroy the cluster:

```bash
# Reset Kubernetes configuration
make cluster-reset

# Delete the VMs
make destroy
```

## Architecture

The deployed cluster consists of:

- Control plane nodes:
  - Ubuntu 24.04 
  - 2 CPU cores
  - 2GB RAM
  - 20GB storage

- Worker nodes:
  - Rocky Linux 9
  - 4 CPU cores 
  - 6GB RAM
  - 80GB storage

Components:
- Container runtime: containerd/cri-o
- CNI: Calico/Cilium/Flannel
- Load balancer: MetalLB
- Ingress: NGINX ingress controller
- Control plane HA: kube-vip

## Customization

The deployment can be customized by modifying:

- `terraform/variables.tf`: VM specifications
- `ansible/group_vars/all.yml`: Kubernetes configuration
- `packer/*/variables.pkr.hcl`: Template settings

## Directory Structure

```
.
├── ansible/           # Ansible playbooks and roles
├── packer/           # Packer templates
│   ├── rocky/       # Rocky Linux template
│   └── ubuntu/      # Ubuntu template  
└── terraform/        # Terraform configurations
```

## License

Apache License 2.0