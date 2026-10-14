#!/usr/bin/env bash
# Builds inventory.ini from Terraform outputs, so IPs are never hard-coded.
set -euo pipefail
cd "$(dirname "$0")"
TF_DIR=../terraform
VM1=$(terraform -chdir=$TF_DIR output -raw vm1_public_ip)
VM2=$(terraform -chdir=$TF_DIR output -raw vm2_private_ip)

cat > inventory.ini << INV
[gateway]
vm1 ansible_host=${VM1}

[app]
# No public IP: reached by jumping through the gateway (bastion pattern)
vm2 ansible_host=${VM2} ansible_ssh_common_args='-o ProxyJump=azureuser@${VM1} -o StrictHostKeyChecking=accept-new'

[all:vars]
ansible_user=azureuser
INV
echo "inventory.ini written: gateway=${VM1}, app=${VM2}"
