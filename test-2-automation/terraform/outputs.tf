output "resource_group" {
  value = azurerm_resource_group.main.name
}

output "vm1_public_ip" {
  description = "Public IP of VM 1 (gateway)"
  value       = azurerm_public_ip.vm1.ip_address
}

output "vm1_private_ip" {
  value = azurerm_network_interface.vm1.private_ip_address
}

output "vm2_private_ip" {
  description = "Private IP of VM 2 (no public IP)"
  value       = azurerm_network_interface.vm2.private_ip_address
}

output "ssh_vm1" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.vm1.ip_address}"
}

output "ssh_vm2_via_vm1" {
  description = "Reach VM 2 by jumping through VM 1"
  value       = "ssh -J ${var.admin_username}@${azurerm_public_ip.vm1.ip_address} ${var.admin_username}@${azurerm_network_interface.vm2.private_ip_address}"
}
