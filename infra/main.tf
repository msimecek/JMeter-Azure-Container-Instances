provider "azurerm" {
   version = "~>1.42.0"
}

resource "azurerm_resource_group" "rg" {
   name        = "LoadTest1"
   location    = "North Europe"
}

resource "azurerm_virtual_network" "vnet" {
   name                 = "loadtestnet"
   location             = "North Europe"
   resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
   name                 = "loadtest"
   resource_group_name  = azurerm_resource_group.rg.name
   virtual_network_name = azurerm_virtual_network.vnet.name  
}

resource "azurerm_storage_account" "storage" {
   name                 = "loadtestresources"
   resource_group_name  = azurerm_resource_group.rg.name
   
}

