variable "prefix" {
    default = "ltinfra5"
}

module "main" {
    source = "./main"
    location = "northeurope"
    prefix = var.prefix
}

module "neu-agents" {
    source      = "./agents"
    location    = "northeurope"
    prefix      = var.prefix
}

module "eus-infra" {
    source          = "./region"
    location        = "eastus"
    main_location   = "northeurope"
    prefix          = var.prefix
}

module "eus-agents" {
    source      = "./agents"
    location    = "eastus"
    prefix      = var.prefix
    agent_count = 1
}
