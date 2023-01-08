terraform {
  required_version = ">=0.12"
}


resource "azurerm_virtual_network" "virtual-network" {
  name                = var.virtual_network_name
  resource_group_name = var.virtual_network_resource_group_name
  location            = var.virtual_network_resource_group_location
  address_space       = var.virtual_network_address_space
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = var.subnet_resource_group_name
  virtual_network_name = azurerm_virtual_network.virtual-network.name
  address_prefixes     = var.subnet_address_prefixes
}