# Este archivo define la infraestructura. 
# Se incluyen recursos como el grupo de recursos, 
# la cuenta de almacenamiento 
# y la clave SSH gestionada por Azure.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Aquí se declara el proveedor de Azure y se configuran las credenciales para la autenticación.
provider "azurerm" {
    features {}
    subscription_id = var.subscription_id
}

# Aquí se declara el grupo de recursos
resource "azurerm_resource_group" "rg" {
    name     = var.resource_group_name
    location = var.location

    tags = {
        environment = var.environment
        project     = var.project
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
        project     = var.project
    }
}

# Generación dinámica de la clave privada SSH
resource "tls_private_key" "azure_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Guardar clave privada y pública localmente
resource "local_file" "private_key" {
  content         = tls_private_key.azure_ssh.private_key_pem
  filename        = "${var.ssh_private_key_path}"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content         = tls_private_key.azure_ssh.public_key_openssh
  filename        = "${var.ssh_public_key_path}"
  file_permission = "0644"
}


# Clave SSH gestionada por Azure
resource "azurerm_ssh_public_key" "ssh" {
    name                = var.ssh_key_name
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location

    public_key = tls_private_key.azure_ssh.public_key_openssh

    tags = {
        environment = var.environment
        project     = var.project
    }
}