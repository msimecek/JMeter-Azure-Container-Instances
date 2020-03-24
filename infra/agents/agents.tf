provider "azurerm" {
   version = "~>2.0"
   features {}
}

variable "prefix" {
}

variable "location" {
}

# variable "registry_server" {
# }

variable "agent_vm_size" {
    default = "Standard_D3_v2" #TODO: lower
}

variable "agent_count" {
    default = 1
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


# ----
# Containers - not used in VMSS mode
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

resource "azurerm_linux_virtual_machine_scale_set" "agentvmss" {
    name                = "${local.dc_name_root}-agents"
    resource_group_name = var.prefix
    location            = var.location
    sku                 = var.agent_vm_size
    instances           = var.agent_count
    
    disable_password_authentication   = false
    admin_username                    = "adminuser"
    admin_password                    = random_password.adminpass.result

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    os_disk {
        storage_account_type = "Standard_LRS"
        caching              = "ReadWrite"
    }

    network_interface {
        name    = "nic"
        primary = true

        ip_configuration {
            name      = "internal"
            primary   = true
            subnet_id = var.region_subnet_id
        }
    }

    #custom_data = base64encode("/jmeter/apache-jmeter-5.2.1/bin/jmeter-server -Dserver.rmi.localport=50000 -Dserver_port=1099 -Dserver.rmi.ssl.disable=true")
}

resource "azurerm_virtual_machine_scale_set_extension" "example" {
    name                         = "init-agent"
    virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.agentvmss.id
    publisher                    = "Microsoft.Azure.Extensions"
    type                         = "CustomScript"
    type_handler_version         = "2.0"
    
    settings = jsonencode({
        "fileUris": [
            "https://raw.githubusercontent.com/msimecek/JMeter-Azure-Container-Instances/vmss/infra/master/master-init.sh",
            "https://raw.githubusercontent.com/msimecek/JMeter-Azure-Container-Instances/vmss/infra/agents/agent-start.sh"
        ],
        "commandToExecute": "./master-init.sh && ./agent-start.sh"
    })

}

# ----
# Outputs
# ----

output "agent_ip" {
    #value = azurerm_network_interface.nic.ip_configuration[0].private_ip_address
    value = "N/A"
}