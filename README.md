# CP2

**Autor:** Óscar Nappo  
**Universidad:** Universidad Internacional de La Rioja (UNIR)  
**Licencia:** MIT-0

---

## Descripción

Este proyecto tiene como objetivo el despliegue completamente automatizado de infraestructura y aplicaciones en Microsoft Azure, abordando los siguientes objetivos:

- **Infraestructura como código** con Terraform para crear y gestionar de forma automatizada todos los recursos necesarios en Azure (redes virtuales, máquinas virtuales, Azure Container Registry, Azure Kubernetes Service, etc.).
- **Gestión de la configuración** con Ansible para automatizar la instalación y configuración de servicios en las máquinas virtuales aprovisionadas.
- **Despliegue de aplicaciones en contenedores** mediante Ansible, utilizando Podman para ejecutar contenedores directamente sobre el sistema operativo con soporte de almacenamiento persistente.
- **Orquestación de contenedores** mediante Ansible para desplegar aplicaciones con almacenamiento persistente sobre un clúster de Kubernetes (AKS).

---

## Requisitos previos

Antes de ejecutar el proyecto, asegúrate de tener instaladas y configuradas las siguientes herramientas:

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html) >= 2.12
- Colección de Ansible `containers.podman`:
  ```bash
  ansible-galaxy collection install containers.podman
  ```
- [Azure CLI](https://learn.microsoft.com/es-es/cli/azure/install-azure-cli) instalado y autenticado:
  ```bash
  az login
  ```
- Una suscripción activa en Microsoft Azure con permisos suficientes para crear recursos (VMs, AKS, ACR, etc.).
- Acceso a un Azure Container Registry (ACR) con las credenciales correspondientes.

---

## Instrucciones de uso

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd cp2
```

### 2. Despliegue de infraestructura con Terraform

Terraform se encarga de crear todos los recursos en Azure de forma automatizada:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

> Revisa siempre el `plan` antes de aplicar para verificar los recursos que se van a crear.

### 3. Aprovisionamiento y despliegue con Ansible

Una vez desplegada la infraestructura, Ansible se encarga de:

- Instalar y configurar los servicios necesarios en las máquinas virtuales.
- Desplegar una aplicación en forma de contenedor sobre el sistema operativo utilizando Podman.
- Desplegar otra aplicación con almacenamiento persistente sobre el clúster AKS.

```bash
cd ansible
ansible-playbook -i inventory playbook.yml
```

> Asegúrate de que el fichero de inventory y las variables necesarias (usuario, contraseña, URL del ACR, etc.) están correctamente configurados antes de ejecutar el playbook.

> Recuerda que puedes personalizar el nombre de los recursos que quieras crear en el fichero `vars.tf`.

### 4. Destruir la infraestructura

Cuando ya no necesites los recursos, puedes eliminarlos con:

```bash
cd terraform
terraform destroy
```

---

## Licencia

Este proyecto está licenciado bajo los términos de la licencia **MIT-0**. Consulta el fichero [LICENSE](./LICENSE) para más información.
