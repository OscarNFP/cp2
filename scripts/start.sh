#!/bin/bash

# ------------------------------------------------------------------------------
# Script: start.sh
# Autor: Óscar Nappo
# Fecha de creación: 01/03/2026
# Proyecto: Despliegue de Infraestructura en Azure con Terraform y Ansible
# Versión: 1.0
# Descripción:
#   Este script muestra un menú interactivo para gestionar el despliegue
#   de la infraestructura en Azure.
# ------------------------------------------------------------------------------

###########################
### BLOQUE DE VARIABLES ###
###########################

# Directorio raiz del Script 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Directorios de trabajo de Terraform
TF_DIR="$ROOT_DIR/terraform"
TF_VARS_FILE="$TF_DIR/vars.tf"


######################################
### BLOQUE DE FUNCIONES AUXILIARES ###
######################################

show_menu() {
    echo "+--------------------------------------------------+"
    echo "+   Despliegue de Infraestructura en Azure         +"
    echo "+--------------------------------------------------+"
    echo "+                                                  +"
    echo "+   0. Salir                                       +"
    echo "+   1. Instalar dependencias                       +"
    echo "+   2. Iniciar despliegue                          +"
    echo "+   3. Destruir infraestructura                    +"
    echo "+                                                  +"
    echo "+--------------------------------------------------+"
    echo ""
    read -rp "Selecciona una opcion [0-3]: " option
}

backup_file(){
    cp "$TF_VARS_FILE" "${TF_VARS_FILE}.template"
}

setear_id(){
    AZ_SUBS_ID=$(az account show --query "id" -o tsv)
    sed -i "s|AZ_SUBS_ID|$AZ_SUBS_ID|g" "$TF_VARS_FILE"
}

destroy_infra(){
    terraform -chdir=$TF_DIR destroy -auto-approve
}

rollback_config_files() {
    if [ -f "${TF_VARS_FILE}.template" ]; then
        mv "${TF_VARS_FILE}.template" "$TF_VARS_FILE"
        echo "Archivo de variables de Terraform restaurado a su estado original."
    fi
}

unset_sensitive_variables() {
    unset SCRIPT_DIR
    unset ROOT_DIR
    unset TF_DIR
    unset TF_VARS_FILE
    unset AZ_SUBS_ID
}

######################
### BLOQUE DE MENÚ ###
######################

while true; do
    show_menu
    case $option in
        0)
            echo ""
            echo "Saliendo..."
	        unset_sensitive_variables
            exit 0
            ;;
        1)
            echo ""
            echo "Instalando dependencias..."
            bash "$SCRIPT_DIR/setup.sh"
	        unset_sensitive_variables
            read -rp "Pulsa Enter para continuar..."
            ;;
        2)
            echo ""
            echo "Iniciando despliegue..."
            bash "$SCRIPT_DIR/init_deploy.sh"
	        unset_sensitive_variables
            read -rp "Pulsa Enter para continuar..."
            ;;
        3)
            echo ""
            echo "Destruyendo infraestructura..."
	        setear_id
	        destroy_infra
	        rollback_config_files
	        unset_sensitive_variables
            read -rp "Pulsa Enter para continuar..."
            ;;
        *)
            echo ""
            echo "Opcion no valida. Por favor, selecciona una opcion entre 1 y 3."
            read -rp "Pulsa Enter para continuar..."
            clear
            ;;
    esac
done
