# AUY1105-Grupo-8

[![CI](https://img.shields.io/github/actions/workflow/status/GMG-bit/AUY1105-Grupo-8/main.yml?branch=main&label=CI&logo=github)](https://github.com/GMG-bit/AUY1105-Grupo-8/actions/workflows/main.yml)
[![Deploy](https://img.shields.io/github/actions/workflow/status/GMG-bit/AUY1105-Grupo-8/deploy.yml?label=Deploy&logo=github)](https://github.com/GMG-bit/AUY1105-Grupo-8/actions/workflows/deploy.yml)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D%201.0.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-~%3E%206.0-FF9900?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![Licencia](https://img.shields.io/badge/Licencia-GPLv3-blue)](LICENSE)

Infraestructura como Código (IaC) con Terraform para el despliegue automatizado de una arquitectura escalable y segura en AWS, desarrollada como parte de la asignatura **AUY1105 – Infraestructura como Código II**.

## 👥 Integrantes

- [@GMG-bit](https://github.com/GMG-bit) — Gaston Mardones
- [@BenjaminDuran](https://github.com/BenjaminDuran) — BenjaminDuran
- [@pacontrerasj](https://github.com/pacontrerasj) — Pablo Contreras

## Características principales

- **Arquitectura de 3 Capas:** VPC con subredes públicas (ALB/NAT GW) y privadas (RDS).
- **Alta Disponibilidad:** Base de Datos PostgreSQL Multi-AZ en subredes privadas.
- **Cómputo Elástico:** Auto Scaling Group (ASG) con Launch Templates y Nginx vía Docker.
- **Seguridad Avanzada:** 
  - VPC Flow Logs auditados en CloudWatch y cifrados con KMS.
  - Gestión flexible de SSH mediante variables.
  - Políticas de cumplimiento con **Open Policy Agent (OPA)**.
- **Pipeline CI/CD:** Análisis estático (TFLint), seguridad (Checkov) y validación de políticas en GitHub Actions.

## Requisitos previos

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configurado con credenciales del Learner Lab
- Key pair `vockey` disponible en la región `us-east-1`
- Bucket S3 para el estado remoto de Terraform.

## Instalación y configuración

Clonar el repositorio e inicializar Terraform:

```bash
git clone https://github.com/GMG-bit/AUY1105-Grupo-8.git
cd AUY1105-Grupo-8

terraform init \
  -backend-config="bucket=NOMBRE_DEL_BUCKET" \
  -backend-config="key=auy1105/terraform.tfstate" \
  -backend-config="region=us-east-1"
```

## Uso y Gestión de Acceso

### Despliegue Estándar
```bash
terraform apply -var="project_name=grupo8" -var="key_name=vockey"
```

### Gestión de SSH (Seguridad Flexible)
Ahora puedes controlar quién accede por SSH directamente desde las variables, facilitando la restricción sin cambiar el código:

```bash
# Abrir a todo el mundo (default aprendizaje)
terraform apply -var="ssh_allowed_cidr=0.0.0.0/0" ...

# Restringir solo a tu IP (recomendado producción)
terraform apply -var="ssh_allowed_cidr=203.0.113.1/32" ...
```

## Estructura del proyecto

```
.
├── modules/
│   ├── vpc/          # Red, Subredes (Públicas/Privadas), NAT GW, Flow Logs
│   ├── balanceador/  # Application Load Balancer (ALB) y Target Groups
│   ├── compute/      # Auto Scaling Group y Launch Templates (Docker/Nginx)
│   └── database/     # RDS PostgreSQL Multi-AZ en subredes privadas
├── policies/         # Reglas de cumplimiento OPA (Rego)
├── Sitio Generico/   # Contenido web estático
├── main.tf           # Orquestación de módulos y Security Groups globales
└── variables.tf      # Definición de variables globales (incluyendo SSH control)
```

## Variables Destacadas

| Variable | Descripción | Default |
|---|---|---|
| `ssh_allowed_cidr` | CIDR permitido para acceso SSH. | `0.0.0.0/0` |
| `project_name` | Nombre del proyecto para etiquetado. | — |
| `private_subnet_cidrs`| Rangos para la capa de datos. | `["10.0.11.0/24", ...]` |

## Políticas de Seguridad (OPA)

El proyecto incluye validaciones automáticas de seguridad:
- **Instancias Permitidas:** Solo se permite el uso de `t2.micro` para control de costos.
- **Control SSH:** (Referencia) Política para detectar accesos públicos, gestionada actualmente vía variables para flexibilidad académica.

## Licencia

Este proyecto se distribuye bajo la licencia **GNU General Public License v3.0**. Consultar el archivo [LICENSE](LICENSE) para más detalles.
