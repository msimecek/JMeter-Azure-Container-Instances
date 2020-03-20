provider "azurerm" {
   version = "~>2.0"
   features {}
}

provider "azuread" {
   version = "~>0.7"
}

provider "random" {}

# Params

variable "location" {
}

variable "main_location" {
}

variable "prefix" {
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

data "azurerm_resource_group" "main_rg" {
   name = var.prefix
}

data "azurerm_virtual_network" "main_vnet" {
    name                = "${var.prefix}-${var.location_short[var.main_location]}-net"
    resource_group_name = var.prefix
}

# ----
# Network + peering
# ----

resource "azurerm_virtual_network" "vnet" {
   name                 = "${local.dc_name_root}-net"
   location             = var.location
   resource_group_name  = data.azurerm_resource_group.main_rg.name
   address_space        = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "subnet_agents" {
   name                 = "agents"
   resource_group_name  = data.azurerm_resource_group.main_rg.name
   virtual_network_name = azurerm_virtual_network.vnet.name
   address_prefix       = "10.2.2.0/24"
   
   delegation {
      name  = "acidelegation"
      service_delegation {
         name  = "Microsoft.ContainerInstance/containerGroups"
         actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
  }
}

resource "azurerm_virtual_network_peering" "peering_to" {
  name                      = "${var.location_short[var.location]}-main"
  resource_group_name       = data.azurerm_resource_group.main_rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.main_vnet.id
}

resource "azurerm_virtual_network_peering" "peering_from" {
  name                      = "main-${var.location_short[var.location]}"
  resource_group_name       = data.azurerm_resource_group.main_rg.name
  virtual_network_name      = data.azurerm_virtual_network.main_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}