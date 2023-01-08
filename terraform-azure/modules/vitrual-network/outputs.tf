output virtula-network {
  value       = azurerm_virtual_network.virtual-network
  description = "virtual network content"
}

output subnet {
  value       = azurerm_subnet.subnet
  description = "subnet content"
}