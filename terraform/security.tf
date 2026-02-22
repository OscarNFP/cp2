# Este archivo define los recursos relacionados con la seguridad de la infraestructura,
# incluyendo el grupo de seguridad de red (NSG) y las reglas de seguridad para permitir
# el tráfico SSH hacia la máquina virtual. Además, se asocia el NSG a la interfaz de red
# para aplicar las reglas de seguridad definidas.

# Security Groups
resource "azurerm_network_security_group" "cp2securitygroup" {
    name                = var.nsg_name
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name                       = var.nsg_rule_name
        priority                   = var.nsg_rule_priority
        direction                  = var.nsg_rule_direction
        access                     = var.nsg_rule_access
        protocol                   = var.nsg_rule_protocol
        source_port_range          = var.nsg_rule_source_port
        destination_port_range     = var.nsg_rule_destination_port
        source_address_prefix      = var.nsg_rule_source_prefix
        destination_address_prefix = var.nsg_rule_destination_prefix
    }

    tags = {
        environment = var.environment
        project     = var.project
    }
}

# Asociar el Network Security Group a la interfaz de red
resource "azurerm_network_interface_security_group_association" "cp2securitygroupassociation" {
    network_interface_id = azurerm_network_interface.cp2nic.id
    network_security_group_id = azurerm_network_security_group.cp2securitygroup.id
}
