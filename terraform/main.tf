terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  #skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
   features {}
  
  #client_id                   = "00000000-0000-0000-0000-000000000000"
  #client_secret               = ""
  #tenant_id                   = "10000000-0000-0000-0000-000000000000"
  #subscription_id             = "20000000-0000-0000-0000-000000000000"
}

terraform{
  backend "azurerm" {
    storage_account_name = ""
    container_name = ""
    key = "filename.tfstate"
    access_key = ""
    feature{}  
  }
}
# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg"
  location = "East US"
}
# Create a virtual network within the resource group
resource "azurerm_virtual_network" "vnet" {
  name                = "rgvnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.vnet.location
  address_space       = ["10.0.0.1/16"]
}
# Create a subnet within the resource group
resource "azurerm_subnet" "subnet" {
  name                 = "rgsubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.evnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
# Create public IPs
resource "azurerm_public_ip" "pip" {
  name                = "${random_pet.prefix.id}-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "nsg" {
  name                = "${random_pet.prefix.id}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "web"
    priority                   = 2001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
# Create virtual machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "rgvm"
  admin_username        = "india"
  admin_password        = rgvm123456
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}
resource "azurerm_container_registry" "acr" {
  name                = "containerRegistry1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Premium"
  admin_enabled       = false
  georeplications {
    location                = "East US"
    zone_redundancy_enabled = true
    tags                    = {}
  }
  georeplications {
    location                = "North Europe"
    zone_redundancy_enabled = true
    tags                    = {}
  }
}