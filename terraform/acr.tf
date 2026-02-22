##################################
# Azure Container Registry (ACR) #
##################################


resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku                 = var.acr_sku
  admin_enabled       = var.acr_admin_enabled

  tags = {
    environment = var.environment
    project     = var.project
  }
}
