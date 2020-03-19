provider "azurerm" {
   version = "~>2.0"
   features {}
}

variable "rg_name" {
}

variable "agent_count" {
   default = "1"
}

variable "registry_server" {
    default = "martinovoload.azurecr.io"
}

variable "registry_username" {
}

variable "registry_password" {
}

# Referencing existing RG
data "azurerm_resource_group" "rg" {
   name = var.rg_name
}

data "azurerm_subnet" "subnet" {
   name                 = "agents"
   resource_group_name  = data.azurerm_resource_group.rg.name
   virtual_network_name = "${var.rg_name}net"
}

resource "azurerm_network_profile" "agent_subnet_profile" {
  name                = "agentsubnetprofile"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  container_network_interface {
    name = "agentnic"

    ip_configuration {
      name      = "agentipconfig"
      subnet_id = data.azurerm_subnet.subnet.id
    }
  }
}

resource "azurerm_container_group" "agents" {
   count                = var.agent_count
   name                 = "loadagent${count.index}"
   resource_group_name  = data.azurerm_resource_group.rg.name
   location             = data.azurerm_resource_group.rg.location
   os_type              = "Linux"
   ip_address_type      = "Private"
   #network_profile_id   = var.network_profile
   network_profile_id   = azurerm_network_profile.agent_subnet_profile.id
   restart_policy       = "Always"

   image_registry_credential {
      username = var.registry_username
      password = var.registry_password
      server = var.registry_server
   }

   container {
      name = "jmeter-agent"
      image = "${var.registry_server}/jmeter-agent"
      cpu = "4"
      memory = "4"

      ports {
         port = 50000
         protocol = "TCP"
      }
      
      ports {
         port = 1099
         protocol = "TCP"
      }
   }
}
