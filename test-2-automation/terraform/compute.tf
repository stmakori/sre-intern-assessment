# Public IP for VM 1 only. Standard SKU (Basic public IPs are retired in Azure).
resource "azurerm_public_ip" "vm1" {
  name                = "${var.prefix}-vm1-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "vm1" {
  name                = "${var.prefix}-vm1-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1.id
  }
}

# VM 2's NIC has NO public IP: only reachable from inside the VNet
resource "azurerm_network_interface" "vm2" {
  name                = "${var.prefix}-vm2-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }
}

locals {
  vms = {
    vm1 = { name = "${var.prefix}-gateway", nic = azurerm_network_interface.vm1.id }
    vm2 = { name = "${var.prefix}-app", nic = azurerm_network_interface.vm2.id }
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = local.vms

  name                  = each.value.name
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [each.value.nic]
  tags                  = local.tags

  # SSH keys only: password login is disabled
  disable_password_authentication = true
  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Ubuntu 22.04 LTS
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
