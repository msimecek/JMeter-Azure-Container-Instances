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
   type = string
   default = "northeurope"
}

variable "prefix" {
   type = string
}

variable "file_share_name" {
   type = string
   default = "test-data"
}


resource "azurerm_resource_group" "rg" {
   name        = var.prefix
   location    = var.location
}

# ----
# Network
# ----

resource "azurerm_virtual_network" "vnet" {
   name                 = "${var.prefix}net"
   location             = azurerm_resource_group.rg.location
   resource_group_name  = azurerm_resource_group.rg.name
   address_space        = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "subnet_master" {
   name                 = "master"
   resource_group_name  = azurerm_resource_group.rg.name
   virtual_network_name = azurerm_virtual_network.vnet.name
   address_prefix       = "10.1.0.0/24"
}

resource "azurerm_subnet" "subnet_agents" {
   name                 = "agents"
   resource_group_name  = azurerm_resource_group.rg.name
   virtual_network_name = azurerm_virtual_network.vnet.name
   address_prefix       = "10.2.0.0/16"
   
   delegation {
      name  = "acidelegation"
      service_delegation {
         name  = "Microsoft.ContainerInstance/containerGroups"
         actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
  }
}

# ----
# Storage
# ----

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

# ----
# Master VM
# ----

# NSG?

resource "azurerm_public_ip" "publicip" {
   name                         = "master-public-ip"
   resource_group_name          = azurerm_resource_group.rg.name
   location                     = azurerm_resource_group.rg.location
   allocation_method            = "Static"
}

resource "azurerm_network_interface" "nic" {
  name                = "master-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_master.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "random_password" "adminpass" {
   length      = 8
   special     = true
}

resource "azurerm_linux_virtual_machine" "mastervm" {
   name                = "${var.prefix}-master"
   resource_group_name = azurerm_resource_group.rg.name
   location            = azurerm_resource_group.rg.location
   size                = "Standard_D8s_v3"
   network_interface_ids = [
      azurerm_network_interface.nic.id,
   ]

   disable_password_authentication   = false
   admin_username                    = "adminuser"
   admin_password                    = random_password.adminpass.result

   custom_data             = filebase64("../master/master-init.sh")

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
# Containers
# ----

resource "azurerm_container_registry" "container_registry" {
   name                 = "${var.prefix}registry"
   location             = azurerm_resource_group.rg.location
   resource_group_name  = azurerm_resource_group.rg.name
   sku                  = "Basic"
   admin_enabled        = true
}

# ----
# Identity
# ----

resource "azurerm_role_assignment" "registry_access" {
   scope                = azurerm_container_registry.container_registry.id
   role_definition_name = "AcrPull"
   principal_id         = azuread_service_principal.principal.id
}

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

# ----
# Outputs
# ----

output "RESOURCE_GROUP" {
  value = azurerm_resource_group.rg.name
}

output "VNET" {
   value = azurerm_virtual_network.vnet.name
}

output "SUBNET" {
   value = azurerm_subnet.subnet_agents.name
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

output "master_admin_username" {
   value = "adminuser"
}

output "master_admin_password" {
   value = random_password.adminpass.result
}