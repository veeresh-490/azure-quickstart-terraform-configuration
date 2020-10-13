locals {
  virtualNetworkName  = "myVNET"
  addressPrefix       = "10.0.0.0/16"
  subnet1Name         = "Subnet-1"
  subnet1Prefix       = "10.0.0.0/24"
  availabilitySetName = "myAvSet"

  imageReference = {
    Ubuntu = {
      publisher = "Canonical",
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    },
    Windows = {
      publisher = "MicrosoftWindowsServer",
      offer     = "WindowsServer",
      sku       = "2019-Datacenter",
      version   = "latest"
    }
  }
  networkSecurityGroupName = "default-NSG"
  nsgOsPort = {
    "Ubuntu"  = "22"
    "Windows" = "3389"
  }
  ssh_key = {
    username   = var.adminUsername
    public_key = file("~/.ssh/id_rsa.pub")
  }
}

# Resource Group
resource "azurerm_resource_group" "arg-01" {
  name     = var.resourceGroupName
  location = var.location
}

# Availabiltyset 
resource "azurerm_availability_set" aas-01 {
  name                         = local.availabilitySetName
  resource_group_name          = azurerm_resource_group.arg-01.name
  location                     = azurerm_resource_group.arg-01.location
  platform_update_domain_count = 2
  platform_fault_domain_count  = 2
  managed                      = true
}

# Network security group
resource "azurerm_network_security_group" "ansg-01" {
  name                = local.networkSecurityGroupName
  resource_group_name = azurerm_resource_group.arg-01.name
  location            = azurerm_resource_group.arg-01.location
  security_rule {
    name                       = join("", ["default-allow-", var.OS])
    priority                   = 1000
    access                     = "Allow"
    direction                  = "Inbound"
    destination_port_range     = local.nsgOsPort[var.OS]
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "avn-01" {
  name                = local.virtualNetworkName
  resource_group_name = azurerm_resource_group.arg-01.name
  location            = azurerm_resource_group.arg-01.location
  address_space       = [local.addressPrefix]
}

# Subnet
resource "azurerm_subnet" "as-01" {
  name                 = local.subnet1Name
  resource_group_name  = azurerm_resource_group.arg-01.name
  virtual_network_name = azurerm_virtual_network.avn-01.name
  address_prefixes     = [local.subnet1Prefix]
}

# Subnet and NSG association
resource "azurerm_subnet_network_security_group_association" "asnsga-01" {
  subnet_id                 = azurerm_subnet.as-01.id
  network_security_group_id = azurerm_network_security_group.ansg-01.id
}

# Network interface with IP configuration
resource "azurerm_network_interface" "anic-01" {
  count               = var.numberOfInstances
  name                = join("", ["nic", count.index])
  resource_group_name = azurerm_resource_group.arg-01.name
  location            = azurerm_resource_group.arg-01.location
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.as-01.id
  }
}

# Create Ubuntu vm
resource "azurerm_linux_virtual_machine" "al-01" {
  count                 = var.OS == "Ubuntu" ? var.numberOfInstances : 0
  name                  = join("", ["myvm", count.index])
  resource_group_name   = azurerm_resource_group.arg-01.name
  location              = azurerm_resource_group.arg-01.location
  size                  = var.vmSize
  availability_set_id   = azurerm_availability_set.aas-01.id
  network_interface_ids = [element(concat(azurerm_network_interface.anic-01.*.id, [""]), count.index)]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = local.imageReference["Ubuntu"]["publisher"]
    offer     = local.imageReference["Ubuntu"]["offer"]
    sku       = local.imageReference["Ubuntu"]["sku"]
    version   = local.imageReference["Ubuntu"]["version"]
  }
  admin_username                  = var.adminUsername
  admin_password                  = var.authenticationType == "sshPublicKey" ? null : var.adminPassword
  disable_password_authentication = var.authenticationType == "sshPublicKey" ? true : false
  dynamic "admin_ssh_key" {
    for_each = var.authenticationType == "sshPublicKey" ? [local.ssh_key] : []
    content {
      username   = admin_ssh_key.value["username"]
      public_key = admin_ssh_key.value["public_key"]
    }
  }
}

# Create Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "aw-01" {
  count                 = var.OS == "Windows" ? var.numberOfInstances : 0
  name                  = join("", ["myvm", count.index])
  resource_group_name   = azurerm_resource_group.arg-01.name
  location              = azurerm_resource_group.arg-01.location
  size                  = "Standard_A0"
  admin_username        = var.adminUsername
  admin_password        = var.adminPassword
  availability_set_id   = azurerm_availability_set.aas-01.id
  network_interface_ids = [element(concat(azurerm_network_interface.anic-01.*.id, [""]), count.index)]
  source_image_reference {
    publisher = local.imageReference["Windows"]["publisher"]
    offer     = local.imageReference["Windows"]["offer"]
    sku       = local.imageReference["Windows"]["sku"]
    version   = local.imageReference["Windows"]["version"]
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
