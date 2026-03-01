#!/bin/bash

# ------------------------------------------------------------------------------
# Script: init_deploy.sh
# Autor: Óscar Nappo
# Fecha de creación: 01/03/2026
# Proyecto: Despliegue de Infraestructura en Azure con Terraform y Ansible
# Versión: 1.1
# Fecha última modificación: 01/03/2026
# Descripción:
#   Este script se encarga de inicializar el entorno para el despliegue
#   de la infraestructura utilizando Terraform y posteriormente configurar 
#   los recursos desplegados utilizando Ansible. 
# ------------------------------------------------------------------------------

# Configuración de seguridad y manejo de errores
# - `set -e`: Hace que el script termine si cualquier comando devuelve un error.
# - `set -u`: Hace que el script termine si se intenta usar una variable no definida.
# - `set -o pipefail`: Hace que el script termine si cualquier comando en una tubería devuelve un error.

set -euo pipefail

# Directorio raíz del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Directorios de configuración
TF_DIR="$ROOT_DIR/terraform"
ANSIBLE_DIR="$ROOT_DIR/ansible"

# Ficheros de configuración
TF_VARS_FILE="$TF_DIR/vars.tf"
ANSIBLE_SECRET_FILE="$ANSIBLE_DIR/secrets.yml"
ANSIBLE_INVENTORY_FILE="$ANSIBLE_DIR/inventory"
ANSIBLE_PLAYBOOK_FILE="$ANSIBLE_DIR/playbook.yml"
ANSIBLE_GLOBAL_VARS="$ANSIBLE_DIR/group_vars/all.yml"

######################################
### BLOQUE DE FUNCIONES AUXILIARES ###
######################################

# Función para imprimir mensajes con timestamp
log() {
    local LEVEL="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$LEVEL] $*"
}

log_info()  { log "INFO"  "$@"; }
log_error() { log "ERROR" "$@"; }
log_notice() { log "NOTICE" "$@"; }


# Función para reemplazar un placeholder en un archivo
replace_placeholder() {
    local placeholder=$1
    local value=$2
    local file=$3

    if ! sed -i "s|$placeholder|$value|g" "$file"; then
        log_error "Error al actualizar $placeholder en $file"
        exit 1
    fi
}

# Funcion para limpiar variables de entorno sensibles al final del script o en caso de error
unset_sensitive_variables() {
    unset AZ_SUBS_ID
    unset ACR_LOGIN_SERVER
    unset ACR_ADMIN_USERNAME
    unset ACR_ADMIN_PASSWORD
    unset VM_PUBLIC_IP
    unset VM_ADMIN_USERNAME
    unset BASIC_USER_PASSWORD
    unset VM_SSH_COMMAND
    unset VM_WEB_URL
    unset CLUSTER_NAME
    unset K8S_NAMESPACE
    unset CL_IP
    unset CL_PORT
    unset FRONTEND_WEB_URL
    unset LOCALHOST_USER
    unset SCRIPT_DIR
    unset ROOT_DIR
}

# Función para restaurar los archivos de configuración a su estado original en caso de error
rollback_config_files() {
    if [ -f "${TF_VARS_FILE}.template" ]; then
        mv "${TF_VARS_FILE}.template" "$TF_VARS_FILE"
        log_notice "Archivo de variables de Terraform restaurado a su estado original."
    fi
    if [ -f "${ANSIBLE_SECRET_FILE}.template" ]; then
        mv "${ANSIBLE_SECRET_FILE}.template" "$ANSIBLE_SECRET_FILE"
        log_notice "Archivo de secretos de Ansible restaurado a su estado original."
    fi
    if [ -f "${ANSIBLE_INVENTORY_FILE}.template" ]; then
        mv "${ANSIBLE_INVENTORY_FILE}.template" "$ANSIBLE_INVENTORY_FILE"
        log_notice "Archivo de inventario de Ansible restaurado a su estado original."
    fi
}

# Función para extraer un output de Terraform de forma segura
# en caso de error, se muestra qué error ocurrió y se termina el script
extract_tf_output() {
    local output_name=$1
    local value

    value=$(terraform -chdir=$TF_DIR output -raw "$output_name" 2>&1)

    if [ -z "$value" ]; then
        log_error "No se pudo obtener el output de Terraform: $output_name"
        exit 1
    fi

    echo "$value"
}

############################
# BLOQUE MANEJO DE ERRORES #
############################

# Configurar un trap para manejar errores y limpiar variables sensibles al finalizar el script. 
# También realiza un rollback de los archivos de configuración en caso de error.
trap 'exit_code=$?; [ $exit_code -ne 0 ] && log_error "El script terminó inesperadamente. Revise los errores arriba indicados"; rollback_config_files; unset_sensitive_variables' EXIT

#################################################
# BLOQUE COMPROBACIÓN DE EXISTENCIA DE FICHEROS #
#################################################

# Comprobar que los archivos de configuración existen
for file in "$TF_VARS_FILE" "$ANSIBLE_SECRET_FILE" "$ANSIBLE_INVENTORY_FILE"; do
    if [ ! -f "$file" ]; then
        log_error "Archivo no encontrado: $file"
        exit 1
    fi
done

# Comprobar que el usuario ha iniciado sesión en Azure CLI
if ! az account show > /dev/null 2>&1; then
    log_error "No se ha iniciado sesión en Azure CLI. Por favor, ejecute 'az login' para iniciar sesión."
    exit 1
fi

####################################################
# BLOQUE BACKUP FICHEROS Y CONFIGURACIÓN TERRAFORM #
####################################################

#Copia de seguridad del archivo de variables de Terraform antes de modificarlo
cp "$TF_VARS_FILE" "${TF_VARS_FILE}.template"

# Configurar Suscripción de Azure en el archivo de variables de Terraform
AZ_SUBS_ID=$(az account show --query "id" -o tsv)
if ! sed -i "s|AZ_SUBS_ID|$AZ_SUBS_ID|g" $TF_VARS_FILE
then
    log_error "Error al actualizar AZ_SUBS_ID en el archivo de variables de Terraform"
    exit 1
fi

##################################################
# BLOQUE DESPLIEGUE INFREAESTRUCTURA - TERRAFORM #
##################################################

# Despliegue de la infraestructura en Terraform
if ! terraform -chdir=$TF_DIR init || ! terraform -chdir=$TF_DIR plan || ! terraform -chdir=$TF_DIR apply -auto-approve; then
    log_error "Error durante la ejecución de Terraform. Verifique los mensajes anteriores para más detalles."
    exit 1
fi

echo ""
log_info "Extrayendo información de la infraestructura desplegada..."

# Extracción de las credenciales del ACR creado
ACR_LOGIN_SERVER=$(extract_tf_output acr_login_server)
ACR_ADMIN_USERNAME=$(extract_tf_output acr_admin_username)
ACR_ADMIN_PASSWORD=$(extract_tf_output acr_admin_password)

# Extracción de datos de la VM
VM_PUBLIC_IP=$(extract_tf_output public_ip_address)
VM_ADMIN_USERNAME=$(extract_tf_output admin_username)
VM_SSH_COMMAND=$(extract_tf_output ssh_connection_command)
VM_WEB_URL=$(extract_tf_output frontend_access_url)

# Extracción de los datos del clúster
CLUSTER_NAME=$(extract_tf_output aks_cluster_name)
#log_info "CLUSTER_NAME: $CLUSTER_NAME"
K8S_NAMESPACE=$(grep 'namespace' $ANSIBLE_GLOBAL_VARS| awk '{print $2}')
#log_info "K8S_NAMESPACE: $K8S_NAMESPACE"

# Generar una contraseña aleatoria para el usuario básico
BASIC_USER_PASSWORD=$(head -c 100 /dev/urandom | tr -dc 'A-Za-z0-9@' | head -c 20 || true)

# Obtener el nombre de usuario del sistema local
LOCALHOST_USER=$(whoami)

echo ""
log_info "Despliegue de infraestructura completado. Procediendo con la configuración de Ansible..."

##################################################
# BLOQUE BACKUP FICHEROS Y CONFIGURACIÓN ANSIBLE #
##################################################

# Copia de seguridad de los archivos de Ansible antes de modificarlos
cp "$ANSIBLE_SECRET_FILE" "${ANSIBLE_SECRET_FILE}.template"
cp "$ANSIBLE_INVENTORY_FILE" "${ANSIBLE_INVENTORY_FILE}.template"

# Actualizar archivo de secretos de Ansible
declare -A secret_replacements=(
    [ACR_LOGIN_SERVER]="$ACR_LOGIN_SERVER"
    [ACR_ADMIN_USERNAME]="$ACR_ADMIN_USERNAME"
    [ACR_ADMIN_PASSWORD]="$ACR_ADMIN_PASSWORD"
    [BASIC_USER_PASSWORD]="$BASIC_USER_PASSWORD"
)

# Reemplazar los placeholders en el archivo de secretos de Ansible
for placeholder in "${!secret_replacements[@]}"; do
    replace_placeholder "$placeholder" "${secret_replacements[$placeholder]}" "$ANSIBLE_SECRET_FILE"
done

log_info "Archivo de secretos de Ansible actualizado correctamente. Configurando inventario..."

# Actualizar archivo de inventario de Ansible
declare -A inventory_replacements=(
    [VM_PUBLIC_IP]="$VM_PUBLIC_IP"
    [LOCALHOST_USER]="$LOCALHOST_USER"
    [VM_USER]="$VM_ADMIN_USERNAME"
    [ACRNAME]="$ACR_ADMIN_USERNAME"
)

# Reemplazar los placeholders en el archivo de inventario de Ansible
for placeholder in "${!inventory_replacements[@]}"; do
    replace_placeholder "$placeholder" "${inventory_replacements[$placeholder]}" "$ANSIBLE_INVENTORY_FILE"
done

log_info "Archivo de inventario de Ansible actualizado correctamente. Listo para ejecutar los playbooks..."

##################################################
# BLOQUE DESPLIEGUE INFREAESTRUCTURA - TERRAFORM #
##################################################

# Ejecutar el playbook de Ansible para configurar los recursos desplegados
ansible-playbook -i $ANSIBLE_INVENTORY_FILE $ANSIBLE_PLAYBOOK_FILE

exit_code=$?

if [ $exit_code -ne 0 ]; then
    log_error "Error al ejecutar el playbook de Ansible (código de salida: $exit_code)"
    
    exit 1
fi

##################
# BLOQUE OUTPUTS #
##################

# Extracción los datos finales del clúster
# Aquí se extrae la dirección IP del servicio Frontend. 
# Se ejecuta en bucle porque puede tardar en obtener la IP
# Una vez que la obtiene, continúa.

log_info "Obteniendo IP externa del servicio fronted..."
CL_IP=""
RETRIES=0
MAX_RETRIES=20

while [ -z "$CL_IP" ] && [ $RETRIES -lt $MAX_RETRIES ]; do
    CL_IP=$(kubectl get service frontend -n $K8S_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -z "$CL_IP" ]; then
        RETRIES=$((RETRIES + 1))
        log_info "Esperando IP externa... intento $RETRIES/$MAX_RETRIES"
        sleep 5
    fi
done

if [ -z "$CL_IP" ]; then
    log_error "No se pudo obtener la IP externa del servicio frontend tras $MAX_RETRIES intentos"
    exit 1
fi

CL_PORT=$(kubectl get service frontend -n $K8S_NAMESPACE -o jsonpath='{.spec.ports[0].port}')
FRONTEND_WEB_URL="http://$CL_IP:$CL_PORT"


log_info "Despliegue completado. Resumen de acceso:"

WIDTH=100

print_line() {
    printf "+%-${WIDTH}s+\n" "" | tr ' ' '-'
}

print_row() {
    printf "+ %-$((WIDTH-2))s +\n" "$1"
}

print_line
print_row ""
print_row "  VM:"
print_row "    IP Publica:       $VM_PUBLIC_IP"
print_row "    Usuario:          $VM_ADMIN_USERNAME"
print_row "    Acceso SSH:       $VM_SSH_COMMAND"
print_row "    Acceso Web:       $VM_WEB_URL"
print_row ""
print_row "  ACR:"
print_row "    Login Server:     $ACR_LOGIN_SERVER"
print_row "    Usuario:          $ACR_ADMIN_USERNAME"
print_row ""
print_row "  Kubernetes:"
print_row "    Cluster:          $CLUSTER_NAME"
print_row "    Acceso Web:       $FRONTEND_WEB_URL"
print_row ""
print_row "  Recuerda que puedes ver el ID de tu suscripción de Azure"
print_row "  con el siguiente comando: az account show --query 'id' -o tsv"
print_row ""
print_line

