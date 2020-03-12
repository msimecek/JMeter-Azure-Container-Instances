provider "azurerm" {
   version = "~>1.42.0"
}

provider "azuread" {
   version = "~>0.7"
}

provider "random" {}

# Params

variable "location" {
   type = string
   default = "North Europe"
}

variable "prefix" {
   type = string
}

variable "file_share_name" {
   type = string
   default = "test-data"
}

# Azure RM

resource "azurerm_resource_group" "rg" {
   name        = var.prefix
   location    = var.location
}

resource "azurerm_virtual_network" "vnet" {
   name                 = "${var.prefix}net"
   location             = azurerm_resource_group.rg.location
   resource_group_name  = azurerm_resource_group.rg.name
   address_space        = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "subnet" {
   name                 = "loadtest"
   resource_group_name  = azurerm_resource_group.rg.name
   virtual_network_name = azurerm_virtual_network.vnet.name
   address_prefix       = "10.1.0.0/16"
   
   delegation {
      name  = "acidelegation"
      service_delegation {
         name  = "Microsoft.ContainerInstance/containerGroups"
      }
  }
}

resource "azurerm_storage_account" "storage" {
   name                 = "loadtestresources"
   location             = azurerm_resource_group.rg.location
   resource_group_name  = azurerm_resource_group.rg.name
   account_kind         = "StorageV2"
   account_tier         = "Standard"
   account_replication_type = "LRS"
}

resource "azurerm_storage_share" "fileshare" {
   name                 = var.file_share_name
   storage_account_name = azurerm_storage_account.storage.name
}

resource "azurerm_storage_share_directory" "results_dir" {
   name                 = "results"
   storage_account_name = azurerm_storage_account.storage.name
   share_name           = azurerm_storage_share.fileshare.name
}

resource "azurerm_container_registry" "container_registry" {
   name                 = "${var.prefix}registry"
   location             = azurerm_resource_group.rg.location
   resource_group_name  = azurerm_resource_group.rg.name
   sku                  = "Basic"
   admin_enabled        = true
}

resource "azurerm_role_assignment" "registry_access" {
   scope                = azurerm_container_registry.container_registry.id
   role_definition_name = "AcrPull"
   principal_id         = azuread_service_principal.principal.id
}

# Azure AD

resource "azuread_application" "principalapp" {
   name                 = "${var.prefix}principal"
   identifier_uris      = ["http://${var.prefix}/principal"]
   available_to_other_tenants = false
   oauth2_allow_implicit_flow = true
}

resource "azuread_service_principal" "principal" {
   application_id       = azuread_application.principalapp.application_id
   app_role_assignment_required  = false
}

resource "random_password" "pass" {
   length   = 16
   special  = true
}

resource "azuread_service_principal_password" "principal_password" {
   service_principal_id = azuread_service_principal.principal.id
   value                = random_password.pass.result
   end_date_relative    = "8760h"
}

# Outputs

output "RESOURCE_GROUP" {
  value = azurerm_resource_group.rg.name
}

output "VNET" {
   value = azurerm_virtual_network.vnet.name
}

output "SUBNET" {
   value = azurerm_subnet.subnet.name
}

output "REGISTRY_USERNAME" {
   value = azuread_service_principal.principal.application_id
}

output "REGISTRY_PASSWORD" {
   value = azuread_service_principal_password.principal_password.value
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

output "registry_server" {
   value = azurerm_container_registry.container_registry.login_server
}

output "registry_admin_username" {
   value = azurerm_container_registry.container_registry.admin_username
}

output "registry_admin_password" {
   value = azurerm_container_registry.container_registry.admin_password
}