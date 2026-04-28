# AUY1105-Grupo-8

[![CI](https://img.shields.io/github/actions/workflow/status/GMG-bit/AUY1105-Grupo-8/main.yml?branch=main&label=CI&logo=github)](https://github.com/GMG-bit/AUY1105-Grupo-8/actions/workflows/main.yml)
[![Deploy](https://img.shields.io/github/actions/workflow/status/GMG-bit/AUY1105-Grupo-8/deploy.yml?label=Deploy&logo=github)](https://github.com/GMG-bit/AUY1105-Grupo-8/actions/workflows/deploy.yml)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D%201.0.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-~%3E%206.0-FF9900?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![Licencia](https://img.shields.io/badge/Licencia-GPLv3-blue)](LICENSE)

Infraestructura como Código (IaC) con Terraform para el despliegue automatizado de una VPC, instancias EC2 con Nginx y VPC Flow Logs en AWS, desarrollada como parte de la Evaluación Parcial N°1 de la asignatura **AUY1105 – Infraestructura como Código II**.

## Características principales

- VPC con dos subredes públicas en distintas zonas de disponibilidad e Internet Gateway.
- Instancia EC2 Ubuntu 24.04 LTS (`t2.micro`) con Nginx preinstalado vía `user_data`, sirviendo un sitio HTML estático.
- VPC Flow Logs completos con CloudWatch Log Group (retención 365 días) y encriptación KMS.
- Pipeline CI/CD con GitHub Actions: análisis estático (TFLint), seguridad (Checkov), validación (`terraform validate`) y políticas OPA, disparado en cada pull request.
- Despliegue automático al crear un tag `v*` y destrucción manual protegida con aprobación de reviewers.

## Requisitos previos

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configurado con credenciales del Learner Lab
- [Git](https://git-scm.com/)
- Bucket S3 creado manualmente para almacenar el estado de Terraform (ver sección de configuración)
- Key pair `vockey` disponible en la región `us-east-1`
- Herramientas opcionales para ejecución local: `tflint`, `checkov`, `opa`

## Instalación y configuración

Clonar el repositorio e inicializar Terraform apuntando al bucket S3 de estado:

```bash
git clone https://github.com/GMG-bit/AUY1105-Grupo-8.git
cd AUY1105-Grupo-8

terraform init \
  -backend-config="bucket=NOMBRE_DEL_BUCKET" \
  -backend-config="key=auy1105/terraform.tfstate" \
  -backend-config="region=us-east-1"
```

Exportar las credenciales temporales del Learner Lab antes de ejecutar cualquier comando que interactúe con AWS:

```bash
export AWS_ACCESS_KEY_ID=ASIA...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
```

> Las credenciales del Learner Lab expiran cada ~4 horas. Deben renovarse antes de cada sesión de trabajo.

## Uso básico

Visualizar el plan sin aplicar cambios:

```bash
terraform plan \
  -var="project_name=grupo8" \
  -var="key_name=vockey"
```

Desplegar la infraestructura:

```bash
terraform apply \
  -var="project_name=grupo8" \
  -var="key_name=vockey" \
  -auto-approve
```

Al finalizar, `terraform output` muestra la IP pública de la instancia. El sitio Nginx queda accesible en `http://<IP_PUBLICA>`.

Acceder a la instancia por SSH:

```bash
ssh -i vockey.pem ubuntu@<IP_PUBLICA>
```

Destruir todos los recursos:

```bash
terraform destroy \
  -var="project_name=grupo8" \
  -var="key_name=vockey" \
  -auto-approve
```

## Variables

| Variable | Descripción | Tipo | Default |
|---|---|---|---|
| `aws_region` | Región de AWS | `string` | `us-east-1` |
| `project_name` | Nombre del proyecto (usado en tags) | `string` | — |
| `vpc_cidr_block` | CIDR de la VPC | `string` | `10.1.0.0/16` |
| `public_subnet_cidrs` | CIDRs de las subredes públicas | `list(string)` | `["10.1.1.0/24", "10.1.2.0/24"]` |
| `instance_count_app1` | Cantidad de instancias EC2 | `number` | `1` |
| `key_name` | Nombre del Key Pair para SSH | `string` | — |

## Outputs

| Output | Descripción |
|---|---|
| `vpc_id` | ID de la VPC creada |
| `public_subnet_ids` | Lista de IDs de las subredes públicas |
| `app1_linux_ips` | IPs públicas de las instancias EC2 |

## Estructura del proyecto

```
.
├── .github/workflows/
│   ├── main.yml          # CI: TFLint, Checkov, terraform validate, OPA (en cada PR)
│   ├── deploy.yml        # CD: despliegue automático al crear tag v*
│   └── destroy.yml       # Destrucción manual con confirmación y aprobación
├── modules/
│   ├── vpc/
│   │   ├── main.tf       # VPC, subredes, IGW, tabla de rutas, Flow Logs + KMS
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── compute/
│       ├── main.tf       # Instancia EC2, AMI Ubuntu 24.04, user_data con Nginx
│       ├── outputs.tf
│       └── variables.tf
├── policies/
│   ├── terraform_security.rego       # Reglas OPA
│   └── terraform_security_test.rego  # Pruebas unitarias de las políticas
├── Sitio Generico/html/  # Sitio HTML estático desplegado en Nginx
├── backend.tf            # Configuración del backend S3
├── main.tf               # Orquestación: VPC, Security Group, módulo compute
├── variables.tf          # Variables globales
├── outputs.tf            # Outputs globales
├── providers.tf          # Proveedor AWS ~> 6.0, Terraform >= 1.0.0
├── CHANGELOG.md
└── README.md
```

## Pipeline CI/CD

El repositorio cuenta con tres workflows de GitHub Actions:

| Workflow | Archivo | Disparador | Descripción |
|---|---|---|---|
| CI | `main.yml` | PR hacia `main` | TFLint → Checkov → terraform validate → OPA tests |
| Deploy | `deploy.yml` | Push de tag `v*` | CI completo + `terraform apply` en AWS |
| Destroy | `destroy.yml` | Manual (`workflow_dispatch`) | `terraform destroy` con confirmación y aprobación de reviewer |

### Secretos y variables requeridos en GitHub

Configurar en **Settings → Secrets and variables → Actions**:

| Nombre | Tipo | Descripción |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Secret | Credencial del Learner Lab |
| `AWS_SECRET_ACCESS_KEY` | Secret | Credencial del Learner Lab |
| `AWS_SESSION_TOKEN` | Secret | Token de sesión del Learner Lab |
| `TF_STATE_BUCKET` | Secret | Nombre del bucket S3 para el estado |
| `KEY_PAIR_NAME` | Secret | Nombre del Key Pair (`vockey`) |
| `PROJECT_NAME` | Variable | Nombre del proyecto (ej. `grupo8`) |

### Despliegue por tag

```bash
git tag v1.0.0
git push origin v1.0.0
```

El workflow `deploy.yml` ejecuta primero todos los checks de calidad y, si pasan, aplica la infraestructura automáticamente.

### Destrucción manual

Ir a **Actions → Terraform Destroy → Run workflow**, escribir `destroy` en el campo de confirmación. El job queda en pausa hasta que un reviewer configurado en el environment `destroy` apruebe la operación.

## Políticas de seguridad con OPA

Las políticas en `policies/terraform_security.rego` se evalúan como pruebas unitarias en cada ejecución del pipeline:

| Política | Descripción |
|---|---|
| Denegar SSH público | Bloquea cualquier `aws_security_group` que abra el puerto 22 desde `0.0.0.0/0` |
| Restricción de instancia | Solo permite instancias de tipo `t2.micro` |

```bash
opa test policies/ -v
```

## Flujo de trabajo colaborativo

La rama `main` está protegida. Todo cambio debe introducirse mediante una rama de características y un pull request:

1. Crear una rama: `git checkout -b feature/descripcion`
2. Realizar cambios y commits con mensajes descriptivos.
3. Abrir un PR hacia `main`; el pipeline CI se dispara automáticamente.
4. Un compañero revisa, comenta y aprueba.
5. Una vez aprobado y con CI en verde, se realiza el merge.

## Contribución

No existe un `CONTRIBUTING.md` formal. Las normas básicas son: commits atómicos en tiempo presente imperativo, un PR por requerimiento o funcionalidad, documentación actualizada en el mismo PR que introduce cambios técnicos, y pipeline CI en verde antes de solicitar revisión.

## Mantenimiento activo

Este README se actualiza junto con el código. Los colaboradores deben verificar su vigencia en cada pull request, asegurando que los comandos, variables y estructura reflejen el estado actual del repositorio.

## Licencia

Este proyecto se distribuye bajo la licencia **GNU General Public License v3.0**. Consultar el archivo [LICENSE](LICENSE) para más detalles.
