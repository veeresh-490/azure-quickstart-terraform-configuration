locals {
  myVNETName                   = "myVNET"
  myVNETPrefix                 = "10.0.0.0/16"
  myVNETSubnet1Name            = "Subnet-1"
  myVNETSubnet1Prefix          = "10.0.0.0/24"
  diagnosticStorageAccountName = lower(join("", ["diagst", random_string.rs.result]))
  operatingSystemValues = {
    Server2012R2 = {
      publisher = "MicrosoftWindowsServer",
      offer     = "WindowsServer"
      sku       = "2012-R2-Datacenter"
    },
    Server2016 = {
      publisher = "MicrosoftWindowsServer",
      offer     = "WindowsServer"
      sku       = "2012-R2-Datacenter"
    },
    Server2019 = {
      publisher = "MicrosoftWindowsServer",
      offer     = "WindowsServer"
      sku       = "2012-R2-Datacenter"
    }
  }
  availabilitySetPlatformFaultDomainCount  = "2"
  availabilitySetPlatformUpdateDomainCount = "5"
  networkSecurityGroupName                 = "default-NSG"
  dnsPrefixForPublicIP                     = lower(join("", [var.dnsPrefixForPublicIP, random_string.rs.result]))
}

# Generate random 
resource "random_string" "rs" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "arg-01" {
  name     = var.resourceGroupName
  location = var.location
}

# Network security group
resource "azurerm_network_security_group" "ansg-01" {
  name                = local.networkSecurityGroupName
  resource_group_name = azurerm_resource_group.arg-01.name
  location            = azurerm_resource_group.arg-01.location
  security_rule {
    name                       = "default-allow"
    priority                   = 1000
    access                     = "Allow"
    direction                  = "Inbound"
    destination_port_range     = 3389
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "avn-01" {
  name                = local.myVNETName
  resource_group_name = azurerm_resource_group.arg-01.name
  location            = azurerm_resource_group.arg-01.location
  address_space       = [local.myVNETPrefix]
}

# Subnet
resource "azurerm_subnet" "as-01" {
  name                 = local.myVNETSubnet1Name
  resource_group_name  = azurerm_resource_group.arg-01.name
  virtual_network_name = azurerm_virtual_network.avn-01.name
  address_prefixes     = [local.myVNETSubnet1Prefix]
}

# Subnet and NSG association
resource "azurerm_subnet_network_security_group_association" "asnsga-01" {
  subnet_id                 = azurerm_subnet.as-01.id
  network_security_group_id = azurerm_network_security_group.ansg-01.id
}

# Storage account
resource "azurerm_storage_account" "asa-01" {
  name                     = lower(local.diagnosticStorageAccountName)
  resource_group_name      = azurerm_resource_group.arg-01.name
  location                 = azurerm_resource_group.arg-01.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  tags = {
    displayName = "diagnosticStorageAccount"
  }
}

# Availabiltyset 
resource "azurerm_availability_set" aas-01 {
  name                         = var.availabilitySetName
  resource_group_name          = azurerm_resource_group.arg-01.name
  location                     = azurerm_resource_group.arg-01.location
  platform_update_domain_count = local.availabilitySetPlatformUpdateDomainCount
  platform_fault_domain_count  = local.availabilitySetPlatformFaultDomainCount
  managed                      = true
}

# Network interface with IP configuration
resource "azurerm_network_interface" "anic-01" {
  count               = var.virtualMachineCount
  name                = join("", [var.virtualMachineNamePrefix, count.index + 1, "NIC1"])
  resource_group_name = azurerm_resource_group.arg-01.name
  location            = azurerm_resource_group.arg-01.location
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(concat(azurerm_public_ip.apip-01.*.id, [""]), count.index)
    subnet_id                     = azurerm_subnet.as-01.id
  }
}

# Public IP
resource "azurerm_public_ip" "apip-01" {
  count               = var.virtualMachineCount
  name                = join("", [var.virtualMachineNamePrefix, count.index + 1, "-PIP1"])
  resource_group_name = azurerm_resource_group.arg-01.name
  location            = azurerm_resource_group.arg-01.location
  allocation_method   = "Dynamic"
  domain_name_label   = join("", [local.dnsPrefixForPublicIP, count.index])
  tags = {
    displayName = join("", [var.virtualMachineNamePrefix, count.index + 1, "-PIP1"])
  }
}

# Create Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "aw-01" {
  count                 = var.virtualMachineCount
  name                  = join("", [var.virtualMachineNamePrefix, count.index + 1])
  resource_group_name   = azurerm_resource_group.arg-01.name
  location              = azurerm_resource_group.arg-01.location
  size                  = var.virtualMachineSize
  admin_username        = var.virtualMachineAdminUserName
  admin_password        = var.virtualMachineAdminPassword
  availability_set_id   = azurerm_availability_set.aas-01.id
  network_interface_ids = [element(concat(azurerm_network_interface.anic-01.*.id, [""]), count.index)]
  provision_vm_agent    = true
  computer_name         = join("", [var.virtualMachineNamePrefix, count.index])
  source_image_reference {
    publisher = local.operatingSystemValues[var.operatingSystem]["publisher"]
    offer     = local.operatingSystemValues[var.operatingSystem]["offer"]
    sku       = local.operatingSystemValues[var.operatingSystem]["sku"]
    version   = "latest"
  }
  os_disk {
    name                 = join("", [var.virtualMachineNamePrefix, count.index + 1])
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.asa-01.primary_blob_endpoint
  }
}
