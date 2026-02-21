# Aquí se declara la red
resource "azurerm_virtual_network" "cp2vnetwork" {
    name                = var.virtual_network_name
    address_space      = var.virtual_network_address_space
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    tags = {
        environment = var.environment
    }
}

# Aquí se declara la subred
resource "azurerm_subnet" "cp2vsubnet" {
    name                 = var.subnet_name
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.cp2vnetwork.name
    address_prefixes     = var.subnet_address_prefixes

    #tags = {
    #    environment = var.environment
    #}
}

# Aquí se declara la interfaz de red NIC
resource "azurerm_network_interface" "cp2nic" {
    name                = var.network_interface_name
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = var.network_interface_ip_configuration_name
        subnet_id                     = azurerm_subnet.cp2vsubnet.id
        private_ip_address_allocation = var.network_interface_private_ip_address_allocation
        #private_ip_address            = var.network_interface_private_ip_address
        public_ip_address_id          = azurerm_public_ip.cp2publicip.id
    }

    tags = {
        environment = var.environment
    }
}

# Aquí se declara la IP pública que será asignada por Azure
resource "azurerm_public_ip" "cp2publicip" {
    name                = var.public_ip_name
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = var.public_ip_allocation_method
    sku                 = var.public_ip_sku

    tags = {
        environment = var.environment
    }
}
