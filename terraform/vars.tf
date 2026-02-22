# Aquí se definen y se asignan valores a las variables utilizadas el resto de archivos.

########################################
# Variables de infraestructura general #
########################################
variable "subscription_id" {
    description = "ID de la suscripción de Azure"
    type        = string
    default     = "tu_subscription_id_aqui"
}

variable "resource_group_name" {
    description = "Nombre del grupo de recursos"
    type        = string
    default     = "cp2ResourceGroup"
}

variable "location" {
    description = "Ubicación de los recursos en Azure"
    type        = string
    default     = "spaincentral"
}

variable "storage_account_name" {
    description = "Nombre de la cuenta de almacenamiento"
    type        = string
    default     = "cp2storageaccount"
}

variable "storage_account_tier" {
    description = "Nivel de la cuenta de almacenamiento (Standard o Premium)"
    type        = string
    default     = "Standard"
}

variable "storage_account_replication_type" {
    description = "Tipo de replicación de la cuenta de almacenamiento (LRS, GRS, RA-GRS)"
    type        = string
    default     = "LRS"
}

variable "ssh_key_name" {
    description = "Nombre de la clave SSH gestionada por Azure"
    type        = string
    default     = "azuresshkey1"
}

variable "ssh_public_key_path" {
    description = "Ruta al archivo de clave pública SSH"
    type        = string
    default     = "~/.ssh/unir/azure/id_rsa_azure.pub"
}

##################################
# Variables de red  - network.tf #
##################################

variable virtual_network_name {
    description = "Nombre de la red virtual"
    type        = string
    default     = "cp2virtualnetwork"
}

variable virtual_network_address_space {
    description = "Rango de red virtual"
    type        = list(string)
    default     = ["10.0.0.0/16"]
}

variable subnet_name {
    description = "Nombre de la subred"
    type        = string
    default     = "cp2subnet"
}

variable subnet_address_prefixes {
    description = "Direcciones para la subred"
    type        = list(string)
    default     = ["10.0.1.0/24"]
}

variable network_interface_name {
    description = "Nombre de la interfaz de red"
    type        = string
    default     = "cp2nic1"
}

variable network_interface_ip_configuration_name {
    description = "Nombre de la configuración de IP para la interfaz de red"
    type        = string
    default     = "cp2ipconfig1"
}

variable network_interface_private_ip_address_allocation {
    description = "Método de asignación de dirección IP privada para la interfaz de red (Static o Dynamic)"
    type        = string
    default     = "Dynamic"
}

variable public_ip_name {
    description = "Nombre de la IP pública"
    type        = string
    default     = "cp2publicip1"
}

variable public_ip_allocation_method {
    description = "Método de asignación de la IP pública (Static o Dynamic)"
    type        = string
    default     = "Static"
}

variable public_ip_sku {
    description = "Nivel de la IP pública (Basic o Standard)"
    type        = string
    default     = "Standard"
}

########################################
# Variables de seguridad - security.tf #
########################################


variable azurerm_network_security_group_name {
    description = "Nombre del Network Security Group"
    type        = string
    default     = "cp2securitygroup1"
}

variable nsg_name {
    description = "Nombre del Network Security Group"
    type        = string
    default     = "cp2securitygroup1"
}

variable "nsg_rule_name" {
    description = "Nombre de la regla de seguridad"
    type    = string
    default = "SecurityRule1"
}

variable "nsg_rule_priority" {
    type    = number
    default = 1001
}

variable "nsg_rule_direction" {
    type    = string
    default = "Inbound"
}

variable "nsg_rule_access" {
    type    = string
    default = "Allow"
}

variable "nsg_rule_protocol" {
    type    = string
    default = "Tcp"
}

variable "nsg_rule_source_port" {
    type    = string
    default = "*"
}

variable "nsg_rule_destination_ports" {
    type    = list(string)
    default = ["22", "8086"]
}

variable "nsg_rule_source_prefix" {
    type    = string
    default = "*"
}

variable "nsg_rule_destination_prefix" {
    type    = string
    default = "*"
}

###########################################
# Variables de la máquina virtual - vm.tf #
###########################################

variable "vm_name" {
    description = "Nombre de la máquina virtual"
    type        = string
    default     = "cp2LinuxVM"
}

variable "vm_size" {
    description = "Tamaño de la máquina virtual"
    type        = string
    default     = "Standard_B2ats_v2" # Este tiene 2 vCPU y 4 GB de RAM
}

variable "vm_zone" {
    description = "Zona disponible para la máquina virtual"
    type        = string
    default     = "3"
}

variable "os_disk_caching" {
    description = "Tipo de caché para el disco del sistema operativo"
    type        = string
    default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
    description = "Tipo de cuenta de almacenamiento para el disco del sistema operativo"
    type        = string
    default     = "Standard_LRS"
}

variable "os_disk_size_gb" {
    description = "Tamaño del disco del sistema operativo en GB"
    type        = number
    default     = 30
}

variable "vm_image_publisher" {
    description = "Editor de la imagen de la máquina virtual"
    type        = string
    default     = "Canonical"
}

variable "vm_image_offer" {
    description = "Imagen de la máquina virtual"
    type        = string
    default     = "0001-com-ubuntu-server-jammy"
}

variable "vm_image_sku" {
    description = "SKU de la imagen de la máquina virtual"
    type        = string
    default     = "22_04-lts-gen2"
}

variable "vm_image_version" {
    description = "Versión de la imagen de la máquina virtual"
    type        = string
    default     = "latest"
}

variable "admin_username" {
    description = "Nombre de usuario administrador para la máquina virtual"
    type        = string
    default     = "ubuntuadmin"
}

######################################
# Variable de entorno para etiquetas #
######################################

variable "environment" {
    description = "Etiqueta de entorno para todos los recursos"
    type        = string
    default     = "development"
}

variable "project" {
    description = "Etiqueta de proyecto para todos los recursos"
    type        = string
    default     = "casopractico2"
}

############################################
# Azure Container Registry variables
############################################

variable "acr_name" {
    description = "Nombre del Azure Container Registry"
    type        = string
    default     = "1acrregcp2"
}

variable "acr_sku" {
    description = "SKU del ACR"
    type        = string
    default     = "Basic"
}

variable "acr_admin_enabled" {
    description = "Habilitar usuario administrador del ACR"
    type        = bool
    default     = true
}
