.DEFAULT_GOAL:=help

.PHONY: ansible packer terraform

# includes environment variables from .env file
ifeq ($(wildcard .env),.env)
include .env
export $(shell sed 's/=.*//' .env)
endif

############################################################

all: ## Run all tasks to provision a Kubernetes cluster
	@ make nodes
	@ echo "Waiting 2 minutes for systems to boot..."
	@ sleep 120
	@ make cluster

############################################################
##@ Kubernetetes applications
############################################################

apps: ## Run Ansible to install Kubernetes applications
	@ cd ansible && ansible-playbook playbooks/setup-cluster.yml -t apps

apps-reset: ## Run Ansible to reset Kubernetes applications
	@ cd ansible && ansible-playbook playbooks/reset-cluster.yml -t apps

############################################################
##@ Kubernetetes cluster
############################################################

ANSIBLE_ARGS ?=

cluster: ## Run Ansible to configure a Kubernetes cluster
	@ cd ansible && ansible-playbook playbooks/setup-cluster.yml $(ANSIBLE_ARGS)

cluster-upgrade: ## Run Ansible to upgrade the cluster nodes
	@ cd ansible && ansible-playbook playbooks/upgrade-cluster.yml $(ANSIBLE_ARGS)

cluster-reset: ## Run Ansible to reset the cluster nodes
	@ cd ansible && ansible-playbook playbooks/reset-cluster.yml $(ANSIBLE_ARGS)

cluster-kubeconfig: ## Generating kubeconfig file for the cluster
	@ cd ansible && ansible-playbook playbooks/setup-cluster.yml -t kubeconfig

############################################################
##@ Nodes
############################################################

nodes: ## Run Terraform to provision nodes for a Kubernetes cluster
	@ cd terraform && terraform init -upgrade && terraform apply -auto-approve

destroy: ## Run Terraform to destroy the cluster nodes
	@ cd terraform && terraform init -upgrade && terraform destroy -target proxmox_virtual_environment_vm.nodes -auto-approve

############################################################
##@ Node Templates
############################################################

rocky: ## Run Packer to build a node template based on Rocky Linux
	@ cd packer && packer build rocky

ubuntu: ## Run Packer to build a node template based on Ubuntu Linux
	@ cd packer && packer init -upgrade ubuntu && packer build ubuntu

############################################################
##@ Help
############################################################
help: ## Display this help
	@ echo "Usage:\n  make \033[36m<target>\033[0m"
	@ awk 'BEGIN {FS = ":.*##"}; \
		/^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)