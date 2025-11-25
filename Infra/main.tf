# 1. Configure the Azure Provider
# This tells Terraform: "We are talking to Azure, not AWS."
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {} # Required boilerplate for Azure
}

# 2. Define the Resource (The "What")
# Syntax: resource "type" "name_in_code"
resource "azurerm_resource_group" "redteam_lab" {
  name     = "rg-devsecops-lab"  # This is the actual name in Azure
  location = "East US 2"            # The datacenter location
}

# 3. Create a Virtual Network
# Notice how we reference the Resource Group's name dynamically?
# If we change the RG name above, this updates automatically.
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-devsecops"
  location            = azurerm_resource_group.redteam_lab.location
  resource_group_name = azurerm_resource_group.redteam_lab.name
  address_space       = ["10.0.0.0/16"]
}

# 1. Create a Subnet (The specific lane in the network)
resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.redteam_lab.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 2. Create a Public IP (So we can reach it from home)
resource "azurerm_public_ip" "public_ip" {
  name                = "vm-pip"
  resource_group_name = azurerm_resource_group.redteam_lab.name
  location            = azurerm_resource_group.redteam_lab.location
  allocation_method   = "Static" # Keep the IP the same
  sku                 = "Standard"
}

# 3. Create a Network Interface (The Virtual Network Card)
resource "azurerm_network_interface" "nic" {
  name                = "vm-nic"
  location            = azurerm_resource_group.redteam_lab.location
  resource_group_name = azurerm_resource_group.redteam_lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# 4. The Virtual Machine (Ubuntu 20.04)
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "target-vm"
  resource_group_name = azurerm_resource_group.redteam_lab.name
  location            = azurerm_resource_group.redteam_lab.location
  size                = "Standard_B1s" # Cheapest option (~$8/month)
  admin_username      = "adminuser"
  admin_password      = var.admin_password 
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

# 5. Output the IP Address (So we don't have to search for it)
output "target_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

# 6. Create Network Security Group (Firewall)
resource "azurerm_network_security_group" "nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.redteam_lab.location
  resource_group_name = azurerm_resource_group.redteam_lab.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.source_ip  
    destination_address_prefix = "*"
  }
}

# 7. Attach Firewall to the Network Interface
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}