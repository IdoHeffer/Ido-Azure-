terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "ido-resources-tf" {
  name     = "ido-resources"
  location = "West Europe"
  tags = {
    enviroment = "dev"
  }
}

module "idos_virtual_network_subnet" {
  source                                  = "./modules/vitrual-network"
  virtual_network_name                    = "ido-vn"
  virtual_network_resource_group_name     = azurerm_resource_group.ido-resources-tf.name
  virtual_network_resource_group_location = azurerm_resource_group.ido-resources-tf.location
  virtual_network_address_space           = ["10.123.0.0/16"]
  subnet_name                             = "ido-subnet"
  subnet_resource_group_name              = azurerm_resource_group.ido-resources-tf.name
  subnet_address_prefixes                 = ["10.123.1.0/24"]
}


resource "azurerm_network_security_group" "ido-sg" {
  name                = "ido-sg1"
  location            = azurerm_resource_group.ido-resources-tf.location
  resource_group_name = azurerm_resource_group.ido-resources-tf.name

  tags = {
    enviroment = "dev"
  }
}

resource "azurerm_network_security_rule" "ido-dev-rule" {
  name                        = "ido-dev-rule1"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.ido-resources-tf.name
  network_security_group_name = azurerm_network_security_group.ido-sg.name
}

resource "azurerm_subnet_network_security_group_association" "ido-sga" {
  subnet_id                 = module.idos_virtual_network_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.ido-sg.id
}

# Create a public IP address for Load balancer for VM's 
resource "azurerm_public_ip" "ido-public-ip" {
  name                = "ido-public-ip"
  resource_group_name = azurerm_resource_group.ido-resources-tf.name
  location            = azurerm_resource_group.ido-resources-tf.location
  allocation_method   = "Static"

  tags = {
    environment = "dev"
  }
}

# Create 2 network interfaces
resource "azurerm_network_interface" "ido-nic" {
  count               = 2
  name                = "ido-nic-${count.index}"
  location            = azurerm_resource_group.ido-resources-tf.location
  resource_group_name = azurerm_resource_group.ido-resources-tf.name

  ip_configuration {
    name                          = "testconfiguration-${count.index}"
    subnet_id                     = module.idos_virtual_network_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create an availability set
resource "azurerm_availability_set" "ido-as" {
  name                         = "myavailabilityset"
  resource_group_name          = azurerm_resource_group.ido-resources-tf.name
  location                     = azurerm_resource_group.ido-resources-tf.location
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
}


# Create 2 virtual machines
resource "azurerm_virtual_machine" "ido-vm" {
  count                 = 2
  name                  = "ido-vm-${count.index}"
  location              = azurerm_resource_group.ido-resources-tf.location
  resource_group_name   = azurerm_resource_group.ido-resources-tf.name
  network_interface_ids = [azurerm_network_interface.ido-nic[count.index].id]
  vm_size               = "Standard_B1s"
  availability_set_id   = azurerm_availability_set.ido-as.id

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "myosdisk-${count.index}"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "ido-vm-${count.index}"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# Create a public IP address
resource "azurerm_public_ip" "ido-chef-public-ip" {
  name                = "ido-chef-public-ip"
  resource_group_name = azurerm_resource_group.ido-resources-tf.name
  location            = azurerm_resource_group.ido-resources-tf.location
  allocation_method   = "Static"

  tags = {
    environment = "dev"
  }
}

# Create 1 chef network interfaces
resource "azurerm_network_interface" "chef-nic" {
  count               = 1
  name                = "chef-nic-${count.index}"
  location            = azurerm_resource_group.ido-resources-tf.location
  resource_group_name = azurerm_resource_group.ido-resources-tf.name

  ip_configuration {
    name                          = "testconfiguration-${count.index}"
    subnet_id                     = module.idos_virtual_network_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ido-chef-public-ip.id
  }
}


resource "azurerm_virtual_machine" "chef-server" {
  count                 = 1
  name                  = "chef-server"
  location              = azurerm_resource_group.ido-resources-tf.location
  resource_group_name   = azurerm_resource_group.ido-resources-tf.name
  network_interface_ids = [azurerm_network_interface.chef-nic[count.index].id]
  vm_size               = "Standard_B2s"
  availability_set_id   = azurerm_availability_set.ido-as.id

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "myosdisk-chef-server"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "chef-server"
    admin_username = "chefadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

data "local_file" "chef_valid_key" {
  filename = "${path.module}/chefserverkey.pem"
}

# resource "azurerm_virtual_machine_extension" "chef" {
#   count                = 2
#   name                 = "chef-extension-${count.index}"
#   virtual_machine_id   = azurerm_virtual_machine.ido-vm[count.index].id
#   publisher            = "Chef.Bootstrap.WindowsAzure"
#   type                 = "LinuxChefClient"
#   type_handler_version = "1210.14"


#   settings = <<SETTINGS
#     {
#       "bootstrap_options": {
#         "chef_server_url": "https://chef-automate-utif.westeurope.cloudapp.azure.com",
#         "validation_client_name": "chef-validator-${count.index}",
#         "validation_key": "${data.local_file.chef_valid_key.content_base64}",
#         "client_rb": {
#         "node_name": "${azurerm_virtual_machine.ido-vm[count.index].name}",
#         "chef_environment": "dev"
#         }
#       },
#       "runlist": [
#         "recipe[docker]"
#       ]
#     }
#   SETTINGS

# }


# Create a load balancer
resource "azurerm_lb" "ido-lb" {
  name                = "ido-lb"
  location            = azurerm_resource_group.ido-resources-tf.location
  resource_group_name = azurerm_resource_group.ido-resources-tf.name
  frontend_ip_configuration {
    name                 = "ido-frontend-ip"
    public_ip_address_id = azurerm_public_ip.ido-public-ip.id
  }

}

resource "azurerm_lb_backend_address_pool" "backend_address_pool" {
  loadbalancer_id = azurerm_lb.ido-lb.id
  name            = "ido-backend-pool"
}

resource "azurerm_lb_rule" "load_balancer_rule" {
  name            = "ido-lb-rule"
  loadbalancer_id = azurerm_lb.ido-lb.id
  # frontend_ip_configuration_id = azurerm_lb.ido-lb.frontend_ip_configuration[0].id
  frontend_ip_configuration_name = "ido-frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_address_pool.id]
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
}

resource "azurerm_lb_probe" "lb_probe" {
  loadbalancer_id     = azurerm_lb.ido-lb.id
  name                = "ido-probe"
  port                = 80
  request_path        = "/"
  protocol            = "Http"
  interval_in_seconds = 15
  number_of_probes    = 2
}

resource "azurerm_lb_nat_rule" "tcp" {
  loadbalancer_id     = azurerm_lb.ido-lb.id
  resource_group_name = azurerm_resource_group.ido-resources-tf.name
  name                = "ido-inbound-nat-rule"
  # frontend_ip_configuration_id    = azurerm_lb.ido-lb.frontend_ip_configuration[0].id
  frontend_ip_configuration_name = "ido-frontend-ip"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
}


# Attach the VMs to the load balancer
resource "azurerm_network_interface_backend_address_pool_association" "ido-lb-asso" {
  count                   = 2
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_address_pool.id
  network_interface_id    = azurerm_network_interface.ido-nic[count.index].id
  ip_configuration_name   = azurerm_network_interface.ido-nic[count.index].ip_configuration[0].name
}

# resource "azurerm_network_interface" "ido-nic1" {
#   name                = "ido-nic1"
#   location            = azurerm_resource_group.ido-resources-tf.location
#   resource_group_name = azurerm_resource_group.ido-resources-tf.name
#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = module.idos_virtual_network_subnet.subnet.id
#     private_ip_address_allocation = "Dynamic"
#     # public_ip_address_id          = azurerm_public_ip.ido-public-ip.id
#   }

#   tags = {
#     enviroment = "dev"
#   }
# }

# resource "azurerm_network_interface" "ido-nic2" {
#   name                = "ido-nic2"
#   location            = azurerm_resource_group.ido-resources-tf.location
#   resource_group_name = azurerm_resource_group.ido-resources-tf.name
#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = module.idos_virtual_network_subnet.subnet.id
#     private_ip_address_allocation = "Dynamic"
#     # public_ip_address_id          = azurerm_public_ip.ido-public-ip.id
#   }

#   tags = {
#     enviroment = "dev"
#   }
# }




# resource "azurerm_linux_virtual_machine" "ido-vm1" {
#   name                  = "ido-vm1"
#   resource_group_name   = azurerm_resource_group.ido-resources-tf.name
#   location              = azurerm_resource_group.ido-resources-tf.location
#   size                  = "Standard_B1s"
#   admin_username        = "adminuser"
#   network_interface_ids = [azurerm_network_interface.ido-nic1.id]



#   admin_ssh_key {
#     username   = "adminuser"
#     public_key = file("~/.ssh/idoazurekey.pub")
#   }

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "16.04-LTS"
#     version   = "latest"
#   }
# }

# resource "azurerm_linux_virtual_machine" "ido-vm2" {
#   name                  = "ido-vm2"
#   resource_group_name   = azurerm_resource_group.ido-resources-tf.name
#   location              = azurerm_resource_group.ido-resources-tf.location
#   size                  = "Standard_B1s"
#   admin_username        = "adminuser"
#   network_interface_ids = [azurerm_network_interface.ido-nic2.id]



#   admin_ssh_key {
#     username   = "adminuser"
#     public_key = file("~/.ssh/idoazurekey.pub")
#   }

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "16.04-LTS"
#     version   = "latest"
#   }
# }