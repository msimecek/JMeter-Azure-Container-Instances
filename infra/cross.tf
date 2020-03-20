provider "azurerm" {
   version = "~>2.0"
   features {}
}

variable "prefix" {
    default = "ltinfra5"
}

variable "main_location" {
    default = "northeurope"
}

variable "registry_username" {
}

variable "registry_password" {
}

resource "azurerm_resource_group" "rg" {
   name        = var.prefix
   location    = var.main_location
}

module "main" {
    source = "./main"
    location = "northeurope"
    prefix = azurerm_resource_group.rg.name
}

module "neu_agents" {
    source      = "./agents"
    location    = "northeurope"
    prefix      = azurerm_resource_group.rg.name
    registry_username   = var.registry_username
    registry_password   = var.registry_password
    region_subnet_id    = module.main.region_subnet_id
}

module "eus_infra" {
    source          = "./region"
    location        = "eastus"
    main_location   = "northeurope"
    prefix          = azurerm_resource_group.rg.name
    main_vnet_id    = module.main.main_vnet_id
    main_vnet_name  = module.main.main_vnet_name
}

module "eus_agents" {
    source      = "./agents"
    location    = "eastus"
    prefix      = azurerm_resource_group.rg.name
    agent_count = 1
    registry_username   = var.registry_username
    registry_password   = var.registry_password
    region_subnet_id    = module.eus_infra.region_subnet_id
}

output "agent_ips" {
    value = list(module.neu_agents.agent_ip, module.eus_agents.agent_ip)
}
