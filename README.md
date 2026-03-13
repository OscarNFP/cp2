# Caso Práctico 2

**Autor:** Óscar Nappo  
**Titulación:** Programa Avanzado DevOps&Cloud  
**Universidad:** Universidad Internacional de La Rioja (UNIR)  
**Licencia:** MIT-0

---

## Descripción

Este proyecto tiene como objetivo el despliegue completamente automatizado de infraestructura y aplicaciones en Microsoft Azure, abordando los siguientes objetivos:

- **Infraestructura como código** con Terraform para crear y gestionar de forma automatizada todos los recursos necesarios en Azure (redes virtuales, máquinas virtuales, Azure Container Registry, Azure Kubernetes Service, etc.).
- **Gestión de la configuración** con Ansible para automatizar la instalación y configuración de servicios en las máquinas virtuales aprovisionadas.
- **Despliegue de aplicaciones en contenedores** mediante Ansible, utilizando Podman para ejecutar contenedores directamente sobre el sistema operativo con soporte de almacenamiento persistente.
- **Orquestación de contenedores** mediante Ansible para desplegar aplicaciones con almacenamiento persistente sobre un clúster de Kubernetes (AKS).

 Todo esto gestionado a través de un script interactivo en bash que es capaz de integrar ambas herramientas, Terraform y Ansible.

---

## Estructura del proyecto

```
cp2
├── ansible
│   ├── ansible.cfg                               # Configuración global de Ansible
│   ├── inventory                                 # Hosts y variables de conexión (IP, usuario, clave SSH)
│   ├── playbook.yml                              # Playbook principal que orquesta todos los roles
│   ├── roles
│   │   ├── acr                                   # Gestión de imágenes en ACR
│   │   │   ├── tasks
│   │   │   │   └── main.yml                      # Login en ACR y push de imágenes
│   │   │   └── vars
│   │   │       └── main.yml                      # Variables del rol: imágenes a gestionar
│   │   ├── aks                                   # Despliegue sobre Kubernetes
│   │   │   ├── tasks
│   │   │   │   └── main.yml                      # Obtención de kubeconfig y despliegue de recursos K8s
│   │   │   ├── templates
│   │   │   │   ├── acr_secrets.yml.j2            # Secret de Kubernetes para acceso al ACR
│   │   │   │   ├── backend.yml.j2                # Deployment y Service del backend (Redis)
│   │   │   │   ├── frontend.yml.j2               # Deployment y Service LoadBalancer del frontend
│   │   │   │   └── persistentvolumeclaim.yml.j2  # PVC para persistencia de datos de Redis
│   │   │   └── vars
│   │   │       └── main.yml                      # Variables del rol: namespace, imágenes, recursos K8s
│   │   └── vm                                    # Configuración de la VM con Podman
│   │       ├── files
│   │       │   └── index.html                    # Página web servida por nginx
│   │       ├── tasks
│   │       │   └── main.yml                      # Instalación de Podman, SSL, htpasswd y arranque del contenedor
│   │       ├── templates
│   │       │   └── nginx.conf.j2                 # Configuración de nginx con HTTPS y autenticación básica
│   │       └── vars
│   │           └── main.yml                      # Variables del rol: puertos, volúmenes, credenciales
│   └── secrets.yml                               # Credenciales (se sube al repositorio con valores sustituibles no válidos)
├── LICENSE                                       # Licencia MIT-0
├── README.md                                     # Documentación del proyecto
├── scripts
│   ├── cleanvars                                 # Limpieza de variables sensibles (solo en modo manual)
│   ├── config                                    # Variables de configuración y rutas del proyecto
│   ├── deploy                                    # Lógica de despliegue de Terraform y Ansible
│   ├── setup                                     # Instalación de dependencias y colecciones Ansible
│   └── start                                     # Menú interactivo principal
└── terraform                                     # Infraestructura como código
    ├── acr.tf                                    # Azure Container Registry
    ├── aks.tf                                    # Azure Kubernetes Service y rol AcrPull
    ├── main.tf                                   # Provider, grupo de recursos, almacenamiento y claves SSH
    ├── network.tf                                # Red virtual, subred, NIC e IP pública
    ├── outputs.tf                                # Outputs: IPs, credenciales ACR, comando SSH
    ├── security.tf                               # Network Security Group y reglas de entrada
    ├── vars.tf                                   # Definición y valores por defecto de todas las variables
    └── vm.tf                                     # Máquina virtual Linux con Ubuntu 22.04

```

---

## Arquitectura
```
Máquina de control
       │
       ├── Terraform ──► Azure Resource Group
       │                      ├── Red virtual + Subred + NIC + IP pública
       │                      ├── Network Security Group (puertos 22, 443, 8086)
       │                      ├── VM Ubuntu 22.04
       │                      ├── ACR (registro privado de imágenes)
       │                      └── AKS (clúster Kubernetes, 1 nodo)
       │
       └── Ansible
              ├──► ACR ──► Push de imágenes (nginx, redis, azure-vote-front)
              │
              ├──► VM ──► nginx (HTTPS + autenticación básica htpasswd)
              │               └── Podman (contenedor nginx con volumen persistente)
              │
              └──► AKS ──► Namespace
                               ├── frontend (azure-vote-front, Service LoadBalancer)
                               └── backend  (Redis, PVC managed-csi)
```

---

## Requisitos previos

Antes de ejecutar el proyecto, asegúrate de tener instaladas y configuradas las siguientes herramientas:

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html) >= 2.12
- [Azure CLI](https://learn.microsoft.com/es-es/cli/azure/install-azure-cli) instalado y autenticado.
- Colecciones Ansible: `containers.podman`, `azure.azcollection`, `community.crypto`, `community.general` y `kubernetes.core`
- Una suscripción activa en Microsoft Azure con permisos suficientes para crear recursos (VMs, AKS, ACR, etc.).
- Acceso a un Azure Container Registry (ACR) con las credenciales correspondientes.

Estas dependencias pueden ser instaladas de forma automática con el script `setup` o bien en modo interactivo lanzando el script `start`
tal y como se explicará a continuación.

---

## Instrucciones de uso

### 1. Clonar el repositorio

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/OscarNFP/cp2.git
cd cp2
```

### 2. Ejecutar menú interactivo

- En el menú interactivo principal podremos elegir entre:

| Opción | Descripción |
|--------|-------------|
| `0` | Salir |
| `1` | Instalar dependencias |
| `2` | Iniciar despliegue |
| `3` | Destruir infraestructura |

Al seleccionar la opción `2` se mostrará un submenú adicional:

| Opción | Descripción |
|--------|-------------|
| `0` | Retroceder al menú principal |
| `1` | Desplegar Infraestructura con Terraform |
| `2` | Desplegar Servicios con Ansible |
| `3` | Desplegar todo [Terraform + Ansible] |

Para comenzar, ejecuta el script:

```bash
./scripts/start
```

---

### De forma alternativa, es posible desplegar toda la infraestructura lanzando los siguientes comandos de forma manual:

### ALT - Terraform: Despliegue de la infraestructura con Terraform


1. Clonar el repositorio, acceder al raíz del proyecto e instalar dependencias:

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/OscarNFP/cp2.git
cd cp2
./scripts/setup
```

2. Configurar Subscription ID obtenido del az login en `vars.tf`:

```bash
cp $TF_VARS_FILE $TF_VARS_FILE.template
AZ_SUBS_ID=$(az account show --query "id" -o tsv)
sed -i'' "s|AZ_SUBS_ID|$AZ_SUBS_ID|g" $TF_VARS_FILE
```
3. Terraform se encarga de crear todos los recursos en Azure de forma automatizada. Para ello ejecutaremos
los siguientes comandos:

```bash
terraform -chdir=$TF_DIR init
terraform -chdir=$TF_DIR plan
terraform -chdir=$TF_DIR apply
```
> [!TIP]
> Recuerda que puedes personalizar el nombre de los recursos en el fichero `vars.tf`.

> [!TIP]
> Es posible aplicar los cambios sin confirmación manual con `terraform apply -auto-approve`

> [!IMPORTANT]
> Revisa siempre el `plan` antes de aplicar para verificar los recursos que se van a crear.

> [!IMPORTANT]
> Si se modifica el provider, ejecuta `terraform -chdir=$TF_DIR init --upgrade` antes del `plan`.

> [!NOTE]
> Revisa la salida output con la información importante de los recursos creados. El comando `terraform -chdir=$TF_DIR output -raw acr_admin_password` devolverá la clave de acceso al ACR.

---

### ALT - Ansible: Aprovisionamiento y despliegue con Ansible

Una vez desplegada la infraestructura con Terraform, Ansible se encarga de:

- Instalar y configurar los servicios necesarios en las máquinas virtuales.
- Desplegar una aplicación en forma de contenedor sobre el sistema operativo utilizando Podman.
- Desplegar otra aplicación con almacenamiento persistente sobre el clúster AKS.


1. Obtener y configurar secretos:

Edita el fichero ansible/secrets.yml sustituyendo los placeholders por los valores obtenidos:

```bash
cp $ANSIBLE_SECRET_FILE $ANSIBLE_SECRET_FILE.template

ACR_LOGIN_SERVER=$(terraform -chdir=$TF_DIR output -raw acr_login_server)
ACR_ADMIN_USERNAME=$(terraform -chdir=$TF_DIR output -raw acr_admin_username)
ACR_ADMIN_PASSWORD=$(terraform -chdir=$TF_DIR output -raw acr_admin_password)
BASIC_USER=$(grep 'usuario_basico' $ANSIBLE_SECRET_FILE| awk -F '\"' '{print $2}')
BASIC_USER_PASSWORD=$(head -c 100 /dev/urandom | tr -dc 'A-Za-z0-9@' | head -c 20)

sed -i'' "s|ACR_LOGIN_SERVER|$ACR_LOGIN_SERVER|g" $ANSIBLE_SECRET_FILE
sed -i'' "s|ACR_ADMIN_USERNAME|$ACR_ADMIN_USERNAME|g" $ANSIBLE_SECRET_FILE
sed -i'' "s|ACR_ADMIN_PASSWORD|$ACR_ADMIN_PASSWORD|g" $ANSIBLE_SECRET_FILE
sed -i'' "s|BASIC_USER_PASSWORD|$BASIC_USER_PASSWORD|g" $ANSIBLE_SECRET_FILE
```

2. Configurar el inventario:

Edita el fichero ansible/inventory sustituyendo los placeholders por los valores obtenidos:

```bash
cp $ANSIBLE_INVENTORY_FILE $ANSIBLE_INVENTORY_FILE.template

ACRNAME=$(terraform -chdir=$TF_DIR output -raw acr_admin_username)
VM_ADMIN_USERNAME=$(terraform -chdir=$TF_DIR output -raw admin_username)
VM_PUBLIC_IP=$(terraform -chdir=$TF_DIR output -raw public_ip_address)

sed -i'' "s|ACRNAME|$ACRNAME|g" $ANSIBLE_INVENTORY_FILE
sed -i'' "s|VM_ADMIN_USERNAME|$VM_ADMIN_USERNAME|g" $ANSIBLE_INVENTORY_FILE
sed -i'' "s|VM_PUBLIC_IP|$VM_PUBLIC_IP|g" $ANSIBLE_INVENTORY_FILE

ssh-keyscan -H "$VM_PUBLIC_IP" >> $KNOWN_HOSTS_LOCAL 2>&1
```

3. Obtener datos de acceso:

```bash
VM_SSH_COMMAND=$(terraform -chdir=$TF_DIR output -raw ssh_connection_command)
VM_WEB_URL_SSL=$(terraform -chdir=$TF_DIR output -raw frontend_access_ssl_url)
CLUSTER_NAME=$(terraform -chdir=$TF_DIR output -raw aks_cluster_name)
K8S_NAMESPACE=$(grep '^app_namespace:' $ANSIBLE_AKS_VARS| awk '{print $2}')
```

4. Cifrar el fichero de secretos con Ansible Vault

```bash
$VENV_DIR/bin/ansible-vault encrypt $ANSIBLE_SECRET_FILE
```
> [!IMPORTANT]
> Aquí pedirá una contraseña para cifrar el fichero. Esta contraseña será necesaria para ejecutar el playbook.

> [!IMPORTANT]
> Nunca ejecutes ansible-vault decrypt sobre el fichero ni hagas commit del fichero descifrado.

> [!TIP]
> Si necesitas modificar el fichero de secretos sin descifrarlo a disco usa:

```bash
$VENV_DIR/bin/ansible-vault edit $ANSIBLE_SECRET_FILE
```

5. Desplegar servicios con Ansible:

```bash
$ANSIBLE_PLAYBOOK_BIN -i $ANSIBLE_INVENTORY_FILE $ANSIBLE_PLAYBOOK_FILE --ask-vault-pass
```
> [!IMPORTANT]
> Durante la ejecución del playbook las credenciales están presentes en memoria como variables de entorno. En un entorno productivo se recomienda sustituir este mecanismo por Azure Key Vault con identidades gestionadas para eliminar completamente las credenciales de la máquina de control.

> [!IMPORTANT]
> Asegúrate de que el fichero de inventory y las variables necesarias (usuario, contraseña, URL del ACR, etc.) están correctamente configurados antes de ejecutar el playbook.

6. Obtener los datos del clúster:

```bash
CL_IP=$(kubectl get service frontend -n $K8S_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
CL_PORT=$(kubectl get service frontend -n $K8S_NAMESPACE -o jsonpath='{.spec.ports[0].port}')
FRONTEND_WEB_URL="http://$CL_IP:$CL_PORT"
```

7. Muestra los resultados:
```bash
echo "  VM:"
echo "    Acceso SSH:       $VM_SSH_COMMAND"
echo "    Acceso Web SSL:   $VM_WEB_URL_SSL"
echo ""
echo "  Kubernetes:"
echo "    Cluster:          $CLUSTER_NAME"
echo "    Acceso Web:       $FRONTEND_WEB_URL"
echo ""
echo "  Clave de acceso a la web:"
echo "    Usuario:          $BASIC_USER"
echo "    Clave:            $BASIC_USER_PASSWORD"
echo ""
```

---

### ALT - Destruir la infraestructura

1. Cuando ya no necesites los recursos, puedes eliminarlos con:

```bash
terraform -chdir=$TF_DIR destroy
```
> Recuerda que puedes hacer que no pida confirmación con el comando `terraform -chdir=$TF_DIR destroy -auto-approve`

2. Limpiar todas las variables de entorno

```bash
mv $TF_VARS_FILE.template $TF_VARS_FILE
mv $ANSIBLE_SECRET_FILE.template $ANSIBLE_SECRET_FILE
mv $ANSIBLE_INVENTORY_FILE.template $ANSIBLE_INVENTORY_FILE

source scripts/cleanvars
```

---

## Problemas conocidos

- **Host key verification failed**: Si redespliegas la infraestructura, ejecuta `ssh-keygen -R <IP>` para limpiar la clave anterior del known_hosts.
- **Terraform state perdido**: Si se pierde el estado, elimina el resource group con `az group delete --name <nombreResourceGroup> --yes` y vuelve a desplegar desde cero.
- **Certificado SSL no válido**: El certificado autofirmado generará un aviso en el navegador. Es el comportamiento esperado sin una CA reconocida.

---

## Licencia

Este proyecto está licenciado bajo los términos de la licencia **MIT-0**. Consulta el fichero [LICENSE](./LICENSE) para más información.
