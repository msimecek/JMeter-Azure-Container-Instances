provider "azurerm" {
   version = "~>1.42.0"
}

variable "prefix" {
  default = "mysample"
}

variable "location" {
  default = "North Europe"
}

resource "azurerm_resource_group" "rg" {
   name        = "${var.prefix}loadtest-rg"
   location    = var.location
}

resource "azurerm_virtual_network" "vnet" {
   name                 = "${var.prefix}loadtestnet"
   location             = azurerm_resource_group.rg.location
   resource_group_name  = azurerm_resource_group.rg.name
   address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "subnet" {
   name                 = "loadtest"
   resource_group_name  = azurerm_resource_group.rg.name
   virtual_network_name = azurerm_virtual_network.vnet.name 
   address_prefix            = "10.1.0.0/16" 

   delegation {
    name = "acidelegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
   }
  }
}

resource "azurerm_storage_account" "storage" {
  name                     = "${var.prefix}loadteststore"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "fileshare" {
  name                 = "loadtestresults"
  storage_account_name = azurerm_storage_account.storage.name
}

output "RESOURCE_GROUP" {
  value = azurerm_resource_group.rg.name
}

output "VNET" {
  value = azurerm_virtual_network.vnet.name
}

output "SUBNET" {
  value = azurerm_subnet.subnet.name
}

output "STORAGE_ACCOUNT_NAME" {
  value = azurerm_storage_account.storage.name
}

output "STORAGE_ACCOUNT_KEY" {
  value = azurerm_storage_account.storage.primary_access_key
}

output "STORAGE_SHARE_NAME" {
  value = azurerm_storage_share.fileshare.name
}