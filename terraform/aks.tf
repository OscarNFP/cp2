############################################
# Azure Kubernetes Service (AKS)
############################################


resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.aks_dns_prefix

  sku_tier = var.aks_sku_tier # "Free" | "Standard"

  default_node_pool {
    name       = var.aks_node_pool_name
    node_count = var.aks_node_count
    vm_size    = var.aks_node_vm_size
  }

  identity {
    type = var.aks_identity_type # "SystemAssigned" | "UserAssigned"
  }
  # Este atributo se usaba en versiones anteriores a v2.x
  # role_based_access_control_enabled = true
  
  # En caso de usar un service_principal para la identidad, se debe agregar el bloque service_principal
  # service_principal {
  #   client_id     = var.aks_sp_client_id
  #   client_secret = var.aks_sp_client_secret
  # }

  # Para versiones v2.x de Terraform Provider, se debe usar el bloque role_based_access_control
  role_based_access_control {
    enabled = true
  }

  tags = {
    environment = var.environment
    project     = var.project
  }
}

############################################
# Permisos AcrPull para AKS sobre el ACR
############################################

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = var.acr_pull_role_name # "AcrPull"
  scope                = azurerm_container_registry.acr.id

  # El bloque depends_on asegura que la asignación de rol se realice 
  # después de que el clúster AKS y el ACR hayan sido creados
  depends_on = [azurerm_kubernetes_cluster.aks, azurerm_container_registry.acr]
}
