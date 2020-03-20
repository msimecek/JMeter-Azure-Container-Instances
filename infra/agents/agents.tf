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

variable "registry_username" {
}

variable "registry_password" {
}

# Referencing existing RG
data "azurerm_resource_group" "rg" {
   name = var.prefix
}

variable "location_short" {
   type = map(string)
   default = {
      northeurope   = "neu",
      westeurope    = "weu",
      eastus        = "eus"
   }
}

locals {
   dc_name_root   = "${var.prefix}-${var.location_short[var.location]}"
}

data "azurerm_subnet" "subnet" {
   name                 = "agents"
   resource_group_name  = data.azurerm_resource_group.rg.name
   virtual_network_name = "${local.dc_name_root}-net"
}

resource "azurerm_network_profile" "agent_subnet_profile" {
  name                = "${local.dc_name_root}subnetprofile"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location # TODO: take from VNET

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
   name                 = "${local.dc_name_root}-loadagent${count.index}"
   resource_group_name  = data.azurerm_resource_group.rg.name
   location             = var.location
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
