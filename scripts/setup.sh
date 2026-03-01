#!/bin/bash

# ------------------------------------------------------------------------------
# Script: setup.sh
# Autor: Óscar Nappo
# Fecha de creación: 01/03/2026
# Proyecto: Despliegue de Infraestructura en Azure con Terraform y Ansible
# Versión: 1.0
# Descripción:
#   Este script instala y configura todas las dependencias necesarias para
#   ejecutar init_deploy.sh. Solo debe ejecutarse una vez por máquina.
# ------------------------------------------------------------------------------

set -euo pipefail

# Función para imprimir mensajes con timestamp
log() {
    local LEVEL="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$LEVEL] $*"
}

log_info()  { log "INFO"  "$@"; }
log_error() { log "ERROR" "$@"; }

# Comprobar que el script se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    log_error "Este script debe ejecutarse como root. Use: sudo ./setup.sh"
    exit 1
fi

# Instalar pip
log_info "Instalando python3-pip..."
apt install -y python3-pip

# Instalar dependencias de Azure para Ansible
log_info "Instalando dependencias de Azure para Ansible..."
pip install 'ansible[azure]' --break-system-packages

# Instalar dependencias de la colección azure.azcollection
log_info "Instalando dependencias de azure.azcollection..."
python3.12 -m pip install -r /usr/lib/python3/dist-packages/ansible_collections/azure/azcollection/requirements.txt --break-system-packages

# Instalar dependencias de Kubernetes
log_info "Instalando dependencias de Kubernetes..."
python3.12 -m pip install kubernetes --break-system-packages

# Instalar colecciones de Ansible
log_info "Instalando colecciones de Ansible..."
ansible-galaxy collection install containers.podman azure.azcollection

# Instalar kubectl
log_info "Instalando kubectl..."
az aks install-cli

# Verificar instalaciones
log_info "Verificando instalaciones..."

for cmd in az terraform ansible ansible-galaxy kubectl; do
    if ! command -v "$cmd" > /dev/null 2>&1; then
        log_error "Dependencia no encontrada tras la instalación: $cmd"
        exit 1
    fi
done

for module in azure.mgmt.containerservice kubernetes; do
    if ! python3.12 -c "import $module" > /dev/null 2>&1; then
        log_error "Módulo Python no encontrado tras la instalación: $module"
        exit 1
    fi
done

for collection in containers.podman azure.azcollection; do
    if ! ansible-galaxy collection list | grep -q "$collection"; then
        log_error "Colección de Ansible no encontrada tras la instalación: $collection"
        exit 1
    fi
done

log_info "Entorno configurado correctamente. Ya puede ejecutar ./init_deploy.sh"