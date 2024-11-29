terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0" # Make sure to use a version that supports 'use_azure_cli'
    }
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"
  features {}
  subscription_id = "444b2bc9-dff3-448c-a660-e4827794bfb7"
  tenant_id       = "4776f7b4-fb8e-4604-9dc9-3bc53126066a"
}

resource "azurerm_resource_group" "azterraform_grp" {
  name     = "azterraform_grp"
  location = "West US 2"
}

resource "azurerm_virtual_network" "azvnet" {
  name                = "azvnet"
  resource_group_name = azurerm_resource_group.azterraform_grp.name
  location            = azurerm_resource_group.azterraform_grp.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "azsubnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.azterraform_grp.name
  virtual_network_name = azurerm_virtual_network.azvnet.name
  address_prefixes     = ["10.0.1.0/24"]

}

# Create a Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.azterraform_grp.location
  resource_group_name = azurerm_resource_group.azterraform_grp.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "aznic_vm1" {
  name                = "aznic"
  resource_group_name = azurerm_resource_group.azterraform_grp.name
  location            = azurerm_resource_group.azterraform_grp.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.azsubnet.id
    private_ip_address_allocation = "Dynamic"

  }
}

resource "azurerm_network_interface" "aznic_vm2" {
  name                = "aznic"
  resource_group_name = azurerm_resource_group.azterraform_grp.name
  location            = azurerm_resource_group.azterraform_grp.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.azsubnet.id
    private_ip_address_allocation = "Dynamic"

  }
}

resource "azurerm_public_ip" "azpubip_vm1" {

  name                = "azpubip_vm1"
  allocation_method   = "Static"
  resource_group_name = azurerm_resource_group.azterraform_grp.name
  location            = azurerm_resource_group.azterraform_grp.location
}

resource "azurerm_network_interface" "aznic_vm1_with_public_ip" {
  name                = "aznic_vm1_with_public_ip"
  resource_group_name = azurerm_resource_group.azterraform_grp.name
  location            = azurerm_resource_group.azterraform_grp.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.azsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azpubip_vm1.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc_vm1" {
  network_interface_id      = azurerm_network_interface.aznic_vm1_with_public_ip.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "azpubip_vm2" {

  name                = "azpubip_vm2"
  allocation_method   = "Static"
  resource_group_name = azurerm_resource_group.azterraform_grp.name
  location            = azurerm_resource_group.azterraform_grp.location
}

resource "azurerm_network_interface" "aznic_vm2_with_public_ip" {
  name                = "aznic_vm2_with_public_ip"
  resource_group_name = azurerm_resource_group.azterraform_grp.name
  location            = azurerm_resource_group.azterraform_grp.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.azsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azpubip_vm2.id
  }
  
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc_vm2" {
  network_interface_id      = azurerm_network_interface.aznic_vm2_with_public_ip.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}



resource "azurerm_linux_virtual_machine" "ansible1" {

  name                = "ansible1"
  computer_name       = "ansible1"
  resource_group_name = azurerm_resource_group.azterraform_grp.name
  location            = azurerm_resource_group.azterraform_grp.location
  size                = "Standard_B1s"
  admin_username      = "rohithsgr"
zone="3"

  network_interface_ids = [
    azurerm_network_interface.aznic_vm1_with_public_ip.id
  ]
  admin_ssh_key {
    username   = "rohithsgr"
    public_key = file("/home/rohithsgr/.ssh/id_ed25519.pub")

  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"

  }

  os_disk {

    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    Name = "Ansible_Node1"
  }
}
resource "azurerm_linux_virtual_machine" "ansible2" {

  name                = "ansible2"
  computer_name       = "ansible2"
  resource_group_name = azurerm_resource_group.azterraform_grp.name
  location            = azurerm_resource_group.azterraform_grp.location
  size                = "Standard_B1s"
  admin_username      = "rohithsgr"
zone="3"
  network_interface_ids = [
    azurerm_network_interface.aznic_vm2_with_public_ip.id
  ]
  admin_ssh_key {
    username   = "rohithsgr"
    public_key = file("/home/rohithsgr/.ssh/id_ed25519.pub")

  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"

  }

  os_disk {

    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    Name = "Ansible_Node2"
  }
}
























