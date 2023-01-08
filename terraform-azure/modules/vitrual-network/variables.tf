variable virtual_network_name {
  type        = string
  description = "the virtual network name"
}

variable virtual_network_resource_group_name {
  type        = string
  description = "the virtual network resource group name"
}

variable virtual_network_resource_group_location {
  type        = string
  description = "the virtual network resource group location"
}

variable virtual_network_address_space {
  type        = list
  description = "virtual network address_space"
}

variable subnet_name {
  type        = string
  description = "subnet_name"
}

variable subnet_resource_group_name {
  type        = string
  description = "the subnet resource group name"
}

variable subnet_virtual_network_name {
  type        = string
  default     = ""
  description = "the subnet virtual network name"
}

variable subnet_address_prefixes {
  type        = list
  description = "subnet address_prefixes"
}

