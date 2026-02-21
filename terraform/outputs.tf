# Este archivo define las salidas del módulo de Terraform,
# proporcionando información útil sobre los recursos creados, 
# como la dirección IP pública de la máquina virtual, 
# el comando SSH para conectarse a ella, el endpoint de diagnósticos de arranque 
# y el nombre de la máquina virtual.

############################################
# IP pública de la máquina virtual
############################################
output "public_ip_address" {
  description = "Dirección IP pública asignada a la VM"
  value       = azurerm_public_ip.cp2publicip.ip_address
}

############################################
# Comando SSH listo para usar
############################################
output "ssh_connection_command" {
  description = "Comando SSH para conectarse a la VM"
  value       = "ssh -i ${var.ssh_public_key_path} ${var.admin_username}@${azurerm_public_ip.cp2publicip.ip_address}"
}

############################################
# Endpoint de diagnósticos de arranque
############################################
output "boot_diagnostics_storage_endpoint" {
  description = "Endpoint del Storage Account usado para los diagnósticos de arranque"
  value       = azurerm_storage_account.storage.primary_blob_endpoint
}

############################################
# Nombre de la máquina virtual
############################################
output "vm_name" {
  description = "Nombre de la máquina virtual creada"
  value       = azurerm_linux_virtual_machine.cp2linuxvm.name
}