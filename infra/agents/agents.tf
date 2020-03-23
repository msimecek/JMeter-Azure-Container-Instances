provider "azurerm" {
   version = "~>2.0"
   features {}
}

variable "prefix" {
}

variable "location" {
}

variable "agent_count" {
   default = "1"
}

variable "registry_server" {
    default = "martinovoload.azurecr.io"
}

variable "agent_vm_size" {
    default = "Standard_D3_v2" #TODO: lower
}

# variable "registry_username" {
# }

# variable "registry_password" {
# }

variable "region_subnet_id" {
}

module "common" {
    source = "../common"
}

locals {
   dc_name_root   = "${var.prefix}-${module.common.location_short[var.location]}"
}

# data "azurerm_subnet" "subnet" {
#    name                 = "agents"
#    resource_group_name  = var.prefix
#    virtual_network_name = "${local.dc_name_root}-net"
# }

# ----
# Containers
# ----

# resource "azurerm_network_profile" "agent_subnet_profile" {
#   name                = "${local.dc_name_root}subnetprofile"
#   resource_group_name = var.prefix
#   location            = var.location # TODO: take from VNET

#   container_network_interface {
#     name = "agentnic"

#     ip_configuration {
#       name      = "agentipconfig"
#       subnet_id = var.region_subnet_id
#     }
#   }
# }



# resource "azurerm_container_group" "agents" {
#    count                = var.agent_count
#    name                 = "${local.dc_name_root}-loadagent${count.index}"
#    resource_group_name  = var.prefix
#    location             = var.location
#    os_type              = "Linux"
#    ip_address_type      = "Private"
#    #network_profile_id   = var.network_profile
#    network_profile_id   = azurerm_network_profile.agent_subnet_profile.id
#    restart_policy       = "Always"

#    image_registry_credential {
#       username = var.registry_username
#       password = var.registry_password
#       server = var.registry_server
#    }

#    container {
#       name = "jmeter-agent"
#       image = "${var.registry_server}/jmeter-agent"
#       cpu = "4"
#       memory = "4"

#       ports {
#          port = 50000
#          protocol = "TCP"
#       }
      
#       ports {
#          port = 1099
#          protocol = "TCP"
#       }
#    }
# }

# ----
# Compute
# ----

resource "azurerm_network_interface" "nic" {
  name                = "${local.dc_name_root}-nic"
  resource_group_name = var.prefix
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.region_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "random_password" "adminpass" {
   length      = 8
   special     = true
}

resource "azurerm_linux_virtual_machine" "agentvm" {
   name                = "${local.dc_name_root}-agent"
   resource_group_name = var.prefix
   location            = var.location
   size                = var.agent_vm_size
   network_interface_ids = [
      azurerm_network_interface.nic.id,
   ]

   disable_password_authentication   = false
   admin_username                    = "adminuser"
   admin_password                    = random_password.adminpass.result

   custom_data             = filebase64("./master/master-init.sh")

   os_disk {
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
   }

   source_image_reference {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "16.04-LTS"
      version   = "latest"
   }
}

# ----
# Outputs
# ----

output "agent_ip" {
    value = azurerm_network_interface.nic.ip_configuration[0].private_ip_address
}