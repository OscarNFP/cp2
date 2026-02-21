# Este archivo define la infraestructura. 
# Se incluyen recursos como el grupo de recursos, 
# la cuenta de almacenamiento 
# y la clave SSH gestionada por Azure.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.1"
    }
  }
}

# Aquí se declara el proveedor de Azure y se configuran las credenciales para la autenticación.
provider "azurerm" {
    features {}
}

# Aquí se declara el grupo de recursos
resource "azurerm_resource_group" "rg" {
    name     = var.resource_group_name
    location = var.location

    tags = {
        environment = var.environment
    }
}

# Aquí se declara el almacenamiento
resource "azurerm_storage_account" "storage" {
    name                     = var.storage_account_name
    resource_group_name      = azurerm_resource_group.rg.name
    location                 = azurerm_resource_group.rg.location
    account_tier             = var.storage_account_tier
    account_replication_type = var.storage_account_replication_type
    tags = {
        environment = var.environment
    }
}

# Clave SSH gestionada por Azure
resource "azurerm_ssh_public_key" "ssh" {
    name                = var.ssh_key_name
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location

    public_key = file(var.ssh_public_key_path)

    tags = {
        environment = var.environment
    }
}