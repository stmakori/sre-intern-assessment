variable "location" {
  description = "Azure region"
  type        = string
  default     = "southafricanorth"
}

variable "prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "sre-assess"
}

variable "vm_size" {
  description = "VM size for both VMs"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "admin_username" {
  description = "Admin user on both VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH PUBLIC key used to log in (the private key never leaves your machine)"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "my_ip" {
  description = "Your public IPv4 address. SSH to VM 1 is only allowed from here. Set via TF_VAR_my_ip."
  type        = string
  sensitive   = true
}

variable "vnet_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}
