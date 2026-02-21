# Este archivo define el recurso de la máquina virtual en Azure utilizando Terraform.
# Se especifican las propiedades de la máquina virtual.

# Creación de la máquina virtual en Azure utilizando Terraform.
resource "azurerm_linux_virtual_machine" "cp2linuxvm" {
    name                = var.vm_name
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    size                = var.vm_size
    admin_username      = var.admin_username
    zone                = var.vm_zone
    disable_password_authentication = true

    # Asociar la máquina virtual a la interfaz de red
    network_interface_ids = [
        azurerm_network_interface.cp2nic.id
    ]

    # Configuración del disco del sistema operativo
    os_disk {
        caching              = var.os_disk_caching
        storage_account_type = var.os_disk_storage_account_type
    }

    # Imagen de la máquina virtual
    source_image_reference {
        publisher = var.vm_image_publisher
        offer     = var.vm_image_offer
        sku       = var.vm_image_sku
        version   = var.vm_image_version
    }
    
    # Clave ssh gestionada por Azure
    admin_ssh_key {
        username   = var.admin_username
        public_key = azurerm_ssh_public_key.ssh.public_key
    }

    # Configuración de diagnóstico de arranque
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.storage.primary_blob_endpoint
    }

    tags = {
        environment = var.environment
    }
}