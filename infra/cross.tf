provider "azurerm" {
   version = "~>2.0"
   features {}
}

variable "prefix" {
    default = "LTuk"
}

variable "main_location" {
    default = "uksouth"
}

resource "azurerm_resource_group" "rg" {
   name        = var.prefix
   location    = var.main_location
}

module "main" {
    source          = "./main"
    location        = var.main_location
    prefix          = lower(azurerm_resource_group.rg.name)
    master_vm_size  = "Standard_DS12_v2" # 4 CPU, 28 RAM
}

# First agent to main location.
module "agents_main" {
    source      = "./agents"
    location    = var.main_location
    prefix      = lower(azurerm_resource_group.rg.name)
    region_subnet_id    = module.main.region_subnet_id
    agent_vm_size       = "Standard_F8s_v2"
    agent_count         = 2
}

# # Provision infrastructure for second region.
# module "region1" {
#     source          = "./region"
#     location        = "canadacentral"
#     main_location   = var.main_location
#     prefix          = lower(azurerm_resource_group.rg.name)
#     main_vnet_id    = module.main.main_vnet_id
#     main_vnet_name  = module.main.main_vnet_name
# }

# # Second agent into second region.
# module "agents_1" {
#     source      = "./agents"
#     location    = "canadacentral"
#     prefix      = lower(azurerm_resource_group.rg.name)
#     region_subnet_id    = module.region1.region_subnet_id
#     agent_vm_size       = "Standard_F8s_v2"
# }

output "master_connection" {
    value = module.main.master_connection
}

output "mount_command" {
    value = module.main.storage_mount_cmd
}

# output "agent_ips" {
#     value = list(module.agents_main.agent_ip, module.agents_1.agent_ip)
# }