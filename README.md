# `AUY1105-grupo-8` - Infraestructura como Código con Terraform

![GitHub Actions](https://img.shields.io/github/actions/workflow/status/AUY1105-grupo-XX/AUY1105-grupo-XX/main.yaml?branch=main&label=CI&logo=github) ![Terraform](https://img.shields.io/badge/Terraform-~%3E%206.0-623CE4?logo=terraform) ![Licencia](https://img.shields.io/badge/Licencia-MIT-green)

## Descripción

Este repositorio alberga el código fuente de infraestructura como código (IaC) desarrollado con Terraform para el despliegue automatizado de recursos en AWS, como parte de la Evaluación Parcial N°1 de la asignatura **AUY1105 – Infraestructura como Código II**. El proyecto implementa una Virtual Private Cloud (VPC) con dos subredes públicas, grupos de seguridad que restringen el acceso SSH exclusivamente a rangos privados, y una instancia EC2 con Ubuntu 24.04 LTS de tipo `t2.micro`. La totalidad del flujo de trabajo se gestiona mediante GitHub Actions, integrando herramientas de análisis estático (TFLint), verificación de seguridad (Checkov), validación sintáctica (`terraform validate`) y cumplimiento de políticas personalizadas mediante Open Policy Agent (OPA). El repositorio sigue un modelo de colaboración basado en pull requests, donde cada cambio requiere revisión por pares antes de ser fusionado a la rama `main`.

## Objetivos

El propósito principal de este proyecto es demostrar la aplicación práctica de los principios de Infraestructura como Código en un entorno cloud controlado, asegurando al mismo tiempo la calidad, seguridad y gobernanza de las configuraciones desplegadas. Los objetivos específicos incluyen: (i) automatizar la creación de una red virtual y cómputo en AWS con Terraform, (ii) implementar un pipeline CI/CD en GitHub Actions que ejecute análisis estático, de seguridad y validación ante cada pull request, (iii) codificar políticas de seguridad mediante OPA para prevenir configuraciones no conformes (acceso SSH público y tipos de instancia no permitidos), y (iv) establecer un flujo de trabajo colaborativo documentado que fomente la revisión de código entre pares, alineándose con los indicadores de logro IL1.1, IL1.2, IL1.3, IL2.1, IL2.2 e IL2.3 de la asignatura.

## Estructura de directorios

```
.
├── .github/workflows/
│   └── main.yaml                # Pipeline CI/CD (TFLint, Checkov, terraform validate, OPA)
├── modules/
│   ├── vpc/
│   │   ├── main.tf              # VPC, subredes, Internet Gateway, tabla de rutas
│   │   ├── outputs.tf           # IDs de VPC y subredes públicas
│   │   └── variables.tf         # Parámetros del módulo VPC
│   └── compute/
│       ├── main.tf              # Instancia EC2 (AMI Ubuntu 24.04, tipo t2.micro)
│       ├── outputs.tf           # IPs públicas e IDs de las instancias
│       └── variables.tf         # Parámetros del módulo compute
├── policies/
│   ├── terraform.rego           # Reglas OPA (denegar SSH público y tipos distintos a t2.micro)
│   └── terraform_test.rego      # Pruebas unitarias para las políticas
├── main.tf                      # Orquestación de módulos (VPC + security group + compute)
├── variables.tf                 # Variables globales del proyecto
├── outputs.tf                   # Salidas globales (VPC ID, subredes, IPs de instancias)
├── providers.tf                # Configuración del proveedor AWS (versión ~>6.0, región)
├── .gitignore                   # Exclusiones de Terraform (estados, tfvars, planos, etc.)
├── CHANGELOG.md                 # Registro de cambios versionados (Keep a Changelog)
└── README.md                    # Este documento
```

## Requisitos previos

Para trabajar con este repositorio se necesita disponer de las siguientes herramientas instaladas en el entorno local:

- **Terraform** (versión >= 1.0.0, compatible con la configuración `required_version` definida en `providers.tf`).
- **AWS CLI** configurado con credenciales de acceso para el laboratorio AWS Learner Lab (no se crean roles IAM personalizados, se utiliza el perfil `LabInstanceProfile` proporcionado por el entorno).
- **Git** para la clonación y gestión de ramas.
- **Opcional pero recomendado:** `tflint`, `checkov` y `opa` para ejecuciones locales fuera del pipeline.

Además, se debe tener acceso al repositorio GitHub con permisos de escritura y capacidad para abrir pull requests. El entorno AWS Learner Lab entrega credenciales temporales que deben ser exportadas como variables de entorno (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) antes de ejecutar cualquier comando Terraform que interactúe con la nube.

## Instalación y configuración inicial

Para comenzar a utilizar el proyecto, clonar el repositorio y posicionarse en el directorio raíz:

```bash
git clone https://github.com/GMG-bit/AUY1105-Grupo-8
cd AUY1105-grupo-8
```

Luego, inicializar el directorio de trabajo de Terraform para descargar los proveedores y módulos necesarios:

```bash
terraform init
```

No se requiere ningún archivo `.tfvars` obligatorio, ya que todas las variables poseen valores por defecto adecuados para el laboratorio. No obstante, la variable `project_name` es obligatoria y debe ser proporcionada en tiempo de ejecución (por ejemplo, mediante `-var="project_name=mi-proyecto"` o a través de un archivo `terraform.tfvars` no versionado). Las credenciales de AWS se toman del entorno automáticamente.

## Ejemplo de uso

Una vez configuradas las credenciales, es posible visualizar el plan de ejecución sin aplicar cambios reales:

```bash
terraform plan -var="project_name=demo"
```

Para desplegar la infraestructura en el laboratorio AWS, ejecutar:

```bash
terraform apply -var="project_name=demo" -auto-approve
```

Al finalizar, se mostrarán las salidas definidas en `outputs.tf`, incluyendo las direcciones IP públicas de la instancia EC2. Para eliminar todos los recursos gestionados, utilizar:

```bash
terraform destroy -var="project_name=demo" -auto-approve
```

**Nota sobre el entorno Learner Lab:** La VPC creada utiliza el bloque CIDR `10.1.0.0/16` y subredes públicas con asignación automática de IPs. Los grupos de seguridad están configurados para permitir tráfico SSH únicamente desde rangos privados (por ejemplo, `10.1.0.0/16`) en cumplimiento de las políticas OPA. En el código actual existe un comentario `#checkov:skip` temporal para facilitar el acceso durante el desarrollo, pero la política final restringe cualquier apertura a `0.0.0.0/0`.

## Flujo de trabajo colaborativo y pull requests

El repositorio sigue un modelo estricto de revisión de código basado en pull requests (PRs). La rama `main` está protegida y no se permite la fusión directa. Cada cambio, ya sea en el código Terraform, en los módulos, en el pipeline de GitHub Actions o en la documentación, debe ser introducido a través de una rama de características y un PR asociado.

**Procedimiento estándar:**

1. Crear una rama local con un nombre descriptivo: `git checkout -b feature/requerimiento-2-infraestructura`.
2. Realizar los cambios y commits con mensajes claros que sigan el formato convencional (ej. `feat: añadir módulo de VPC`, `fix: corregir regla de salida del security group`).
3. Subir la rama al repositorio remoto y abrir un pull request hacia `main`. El PR debe incluir una descripción detallada de los cambios, referencias a los indicadores de logro que se abordan, y cualquier información relevante para el revisor.
4. El compañero de equipo (reviewer) debe analizar el código, ejecutar el pipeline de forma automática (se dispara en cada PR) y dejar comentarios específicos, sugerencias o solicitudes de modificación.
5. Una vez que el pipeline pase (TFLint, Checkov, `terraform validate` y OPA) y el revisor apruebe el PR, se puede proceder al merge (preferentemente mediante squash o merge convencional según la política del equipo).

**Requerimiento mínimo de evaluación:** Cada integrante del equipo debe participar activamente como autor en al menos dos pull requests documentados (uno por cada uno de los cuatro requerimientos: Repositorio, Código, Automatización, Políticas). El compañero debe revisar, comentar y aprobar o rechazar los cambios, evidenciando así la aplicación de buenas prácticas de revisión de código (IL1.1).

## Políticas de seguridad con Open Policy Agent (OPA)

Con el objetivo de garantizar que la infraestructura desplegada cumpla con estándares de seguridad y gobernanza, se han desarrollado dos políticas codificadas en el lenguaje Rego, ubicadas en el directorio `policies/`. Estas políticas son evaluadas automáticamente dentro del pipeline de GitHub Actions mediante el comando `opa test policies/ -v`. Las reglas implementadas son:

1. **Prohibición de SSH público**: Cualquier recurso de tipo `aws_security_group` o `aws_security_group_rule` que intente abrir el puerto 22 (TCP) con `cidr_blocks` que incluya `"0.0.0.0/0"` o `"::/0"` será denegado, impidiendo así la exposición innecesaria del servicio de administración.
2. **Restricción del tipo de instancia EC2**: Se permite exclusivamente el tipo `t2.micro` para todos los recursos de tipo `aws_instance`. Cualquier otro valor (`t2.large`, `t3.micro`, etc.) generará una violación de la política.

La evaluación se realiza sobre el plan de Terraform en formato JSON (generado con `terraform show -json`), lo que permite analizar los cambios propuestos antes de que sean aplicados. Si alguna de las políticas falla, el pipeline marca el paso como fallido y el pull request no puede ser fusionado, asegurando que ninguna configuración no conforme llegue al entorno productivo. El archivo `policies/terraform_test.rego` contiene pruebas unitarias que verifican el comportamiento esperado de las reglas, tal como se demuestra en los escenarios de prueba incluidos.

## Variables de entorno y secretos

El pipeline de GitHub Actions no requiere secretos adicionales porque el despliegue real de recursos no se ejecuta de forma automática (solo se realizan análisis estáticos y validaciones sin conexión). Sin embargo, para ejecuciones locales con `terraform apply` o `terraform plan`, se deben configurar las siguientes variables de entorno proporcionadas por AWS Learner Lab:

```bash
export AWS_ACCESS_KEY_ID=ASIA...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
```

Estas credenciales tienen una duración limitada y no deben ser incluidas en archivos del repositorio. El archivo `.gitignore` excluye expresamente `*.tfvars`, `*.tfstate`, `*.pem` y `*.env` para evitar el versionado accidental de información sensible.

## Contribución y directrices adicionales

Se espera que todo colaborador lea y siga las pautas establecidas en el archivo [`CONTRIBUTING.md`](CONTRIBUTING.md) (pendiente de creación, pero se sugiere su implementación). De forma resumida, las normas básicas son:

- Los commits deben ser atómicos y estar redactados en tiempo presente imperativo.
- Cada pull request debe contener únicamente cambios relacionados con un mismo requerimiento o funcionalidad.
- La documentación (README, CHANGELOG) debe actualizarse en el mismo PR que introduce modificaciones relevantes.
- El pipeline de CI debe pasar en su totalidad antes de solicitar una revisión.
- Se fomenta el uso de comentarios constructivos durante la revisión, señalando tanto aciertos como áreas de mejora.

## Mantenimiento activo del README

Este documento se considera un artefacto vivo del repositorio. Por lo tanto, cualquier modificación en la estructura de directorios, en los comandos de uso, en las políticas de seguridad o en el flujo de trabajo colaborativo debe ir acompañada de la correspondiente actualización de este README. Durante la revisión de un pull request, el revisor deberá verificar que los cambios documentales sean coherentes con las modificaciones técnicas introducidas, tal como se establece en el indicador IL1.3.

## Licencia

Este proyecto se distribuye bajo la licencia MIT. Consulte el archivo [`LICENSE`](LICENSE) para más detalles.