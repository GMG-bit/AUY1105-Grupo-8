# Changelog

Todas las modificaciones importantes de este proyecto se documentarán en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/)
y las versiones se ordenan de la más reciente a la más antigua.

---

## [Unreleased]

### Añadido
- **Despliegue Dinámico y Ligero del Sitio E-Commerce (S3 Sync):**
  - Creado un bucket seguro de **Amazon S3** (`aws_s3_bucket.assets`) con cifrado predeterminado por AES256, bloqueo completo de acceso público y habilitación de versionado (`aws_s3_bucket_versioning`).
  - Implementada una subida dinámica de la estructura de archivos estáticos de `Sitio Generico/html` utilizando `aws_s3_object` con un mapa local de MIME types (`mime_types`) para asegurar que el navegador cargue los recursos (.html, .css, .js, .woff2, etc.) con sus tipos de contenido correctos.
  - Automatizada la instalación de **AWS CLI v2** y la sincronización recursiva (`aws s3 sync`) de los archivos del sitio en el arranque (EC2 `user_data`) de forma eficiente, eliminando el bloat y peso en la plantilla de lanzamiento.
- **Identificación Dinámica de Servidores y Banner de Balanceo (HA Demo):**
  - Implementada consulta dinámica a metadatos de instancia **IMDSv2** en el script de arranque para extraer de manera segura el `Instance ID`, la `IP Privada` y la `Zona de Disponibilidad` (AZ) del nodo.
  - Inyección automatizada de un **Banner Flotante Premium** y moderno (con diseño estilizado de degradados, bordes redondeados y tipografía sin serifa) en la parte superior de la página principal (`index.html`) mediante un comando `sed` seguro y no invasivo en tiempo de arranque.
  - Configurado el contenedor de **Docker Nginx** para levantar la aplicación web montando la ruta local modificada (`-v /var/www/html:/usr/share/nginx/html`), demostrando visualmente el balanceo de carga entre los nodos al recargar rápidamente el balanceador de aplicaciones (ALB).

---

## [2026-05-21]

### Añadido
- **Monitoreo Continuo y Alertas:**
  - Integración de **Amazon CloudWatch Agent** automatizado vía `user_data` en las instancias EC2 para medir CPU activa, memoria RAM, disco y red.
  - Alarma de CloudWatch por alto uso de CPU (>70%) a nivel del Auto Scaling Group.
  - Alarma de CloudWatch por alto uso de Memoria (>70%) a nivel de sistema operativo (CWAgent).
  - Tema de **Amazon SNS** (`alerts-topic`) y suscripción por correo electrónico dirigida a `gas.mardones@duocuc.cl` para recibir alertas automáticas.
  - Dashboard de monitoreo interactivo en CloudWatch (`monitoring-dashboard`) que recopila y grafica el estado del ASG, RAM del agente, peticiones del ALB y uso de CPU de RDS.
- **Planes de Respaldo (DR):**
  - Configuración automatizada de **AWS Backup** (Bóveda centralizada, plan de respaldo diario y retención automática de 7 días).
  - Selección de recursos dinámica: EC2 mediante la etiqueta `BackupClass = "DailyBackup"` y base de datos RDS MySQL mediante ARN, utilizando el rol preexistente `LabRole`.
- **Gobernanza de Seguridad (OPA):**
  - Añadida regla OPA para auditar plantillas de lanzamiento (`aws_launch_template`) forzando el tipo de instancia `t3.small` en `policies/terraform_security.rego`.
  - Sincronizados los tests unitarios de Rego en `policies/terraform_security_test.rego` para validar `t3.small` y denegar tipos inferiores.
- **Resolución de Bugs Estructurales:**
  - Creado `variables.tf` para el módulo `balanceador` declarando los parámetros `project_name`, `vpc_id` y `public_subnet_ids`.
  - Creado `outputs.tf` para el módulo `database` declarando la salida `db_endpoint` para evitar caídas de referencia en el módulo raíz.

### Cambios
- **Capa de Cómputo (Alta Disponibilidad):**
  - Servidores del Auto Scaling Group escalados a **`t3.small`** con volumen de arranque de **50 GB gp3 SSD cifrado**, con IMDSv2 forzado y perfil de instancia `LabInstanceProfile`.
  - Capacidades del Auto Scaling Group configuradas en alta disponibilidad multizona: **Mínimo 2, Deseado 2, Máximo 3**.
- **Capa de Datos:**
  - Base de datos migrada a **RDS MySQL 8.0 db.t4g.small Multi-AZ con 50 GB gp3 SSD cifrado** en subredes privadas.
  - Security Group de base de datos (`db_sg`) adaptado para admitir tráfico en el puerto estándar MySQL **`3306`** desde los servidores.
- **Capa de Balanceo:**
  - Grupo de seguridad del ALB actualizado para soportar puertos **80 (HTTP)** y **443 (HTTPS)** de forma pública.
  - Salidas de Terraform (`outputs.tf`) del directorio raíz e interfaces corregidas para apuntar la URL del sitio web (`url_sitio_web`) directamente al DNS público del balanceador.
- **Documentación del Proyecto:**
  - **README.md** actualizado con el diagrama interactivo de arquitectura en Mermaid con sintaxis corregida, tabla de variables parametrizadas e instrucciones de pruebas de failover.
  - Creada la **[Guía de Pruebas de HA y DR (walkthrough.md)](file:///C:/Users/timti/.gemini/antigravity/brain/5e7d482d-3a85-47f6-9b9e-43e4a39e26b4/walkthrough.md)** para la documentación de fallos y evidencias en la entrega final.

---

## [2026-04-28]

### Añadido
- Definidas políticas de seguridad usando Open Policy Agent (OPA) para reforzar la configuración de Terraform ([#9](https://github.com/GMG-bit/AUY1105-Grupo-8/pull/9)).
  - Denegar acceso SSH público para cualquier `aws_security_group`.
  - Permitir solo instancias EC2 de tipo `t2.micro`.
  - Pruebas unitarias Rego agregadas y 3/3 tests pasan localmente.
  - Integración de paso OPA en el pipeline de GitHub Actions.
- Agregado pipeline CI: análisis estático TFLint, seguridad Checkov, `terraform validate` y tests OPA en cada pull request hacia `main` ([#6](https://github.com/GMG-bit/AUY1105-Grupo-8/pull/6)).
- Agregado workflow `deploy.yml`: despliegue automático de infraestructura al crear un tag `v*`. Ejecuta el CI completo antes de `terraform apply`; usa backend S3 parcial configurado vía secretos de GitHub.
- Agregado workflow `destroy.yml`: destrucción manual de infraestructura vía `workflow_dispatch`. Requiere que el operador escriba `destroy` como confirmación y que un reviewer apruebe el job a través del GitHub Environment `destroy`.
- Agregado `backend.tf` con bloque S3 vacío para configuración parcial del estado remoto en tiempo de `terraform init` mediante flags `-backend-config`.
- Habilitado acceso SSH (puerto 22, `0.0.0.0/0`) en el Security Group de servidores ([#10](https://github.com/GMG-bit/AUY1105-Grupo-8/pull/10)). Requerido por restricción del AWS Learner Lab que no permite SSM Session Manager; skip `CKV_AWS_24` documentado en código y pipeline.
- Agregada variable `key_name` en `variables.tf` para parametrizar el Key Pair de AWS (`vockey`), almacenado como secreto `KEY_PAIR_NAME` en GitHub Actions.
- Sitio HTML estático ampliado con páginas completas: `service.html`, `team.html`, `about.html`, `client.html` y `contact.html`. Incluye slider interactivo (`slider-setting.js`), assets CSS (Bootstrap, Animate, Owl Carousel), JavaScript y recursos visuales (fuentes Poppins, Font Awesome, imágenes). Subido directamente a `main` (commit `922f627`).
- Script de instalación de Nginx incorporado en `user_data` del módulo `compute`: instala Nginx, lo habilita como servicio y despliega el contenido de `Sitio Generico/html/index.html` automáticamente al lanzar la instancia EC2. Subido directamente a `main` (commit `922f627`).
- Agregada variable `html_content` en el módulo `compute` y output `url_sitio_web` con la URL HTTP de la instancia. Subido directamente a `main` (commit `922f627`).

### Cambios
- Limpieza y ajuste de la infraestructura Terraform para EP1 ([#8](https://github.com/GMG-bit/AUY1105-Grupo-8/pull/8)):
  - Eliminación de módulos (ALB, backend_servers, RDS, S3+CloudFront) y archivos estáticos innecesarios.
  - Corrección de bug en outputs y variables.
  - Prefijos `AUY1105-` agregados en recursos VPC.
  - Providers y variables renovados y alineados.
  - Mejoras de seguridad: disco cifrado, Flow Logs con KMS, egress restringido, IMDSv2 forzado.
  - Justificaciones de skips documentadas con comentarios `checkov:skip` en código.
- Módulo `compute`: agregado parámetro `key_name`, `user_data` con script de instalación de Nginx y variable `html_content` para inyectar el sitio HTML estático en la instancia.
- Workflow CI `main.yml`: agregado `CKV_AWS_24` a la lista de skips de Checkov, alineado con la excepción documentada en `main.tf`.
- README.md reescrito por completo: badges correctos, sección de CI/CD con los tres workflows, tabla de secretos y variables de GitHub, instrucciones de acceso SSH, descripción de políticas OPA y licencia GPLv3.

### Eliminado
- Archivos no requeridos: `index.html`, `error.html`, `logo.png`, `plan.tfplan`.
- Módulos y variables de infraestructura que no son requeridos por la consigna EP1.

---

## [2026-04-27]

### Añadido
- Estructura de proyecto Terraform inicial ([#1](https://github.com/GMG-bit/AUY1105-Grupo-8/pull/1)).
- Archivos y flujos iniciales de trabajo en `.github/workflows/`.
- Agregado `.gitignore` para ignorar archivos generados y temporales ([#5](https://github.com/GMG-bit/AUY1105-Grupo-8/pull/5)).

### Cambios
- Varias mejoras y simplificaciones en la definición de los recursos de infraestructura ([#4](https://github.com/GMG-bit/AUY1105-Grupo-8/pull/4), [#7](https://github.com/GMG-bit/AUY1105-Grupo-8/pull/7)):
  - Se actualizan variables de red y CIDR.
  - Se comentan módulos de bases de datos y outputs innecesarios.
  - Se mejora seguridad predeterminada en grupos de seguridad.
- Se asegura la infraestructura alineada a requerimientos del curso (subredes, VPC, enable VPC Flow Logs, EC2 Ubuntu 24.04 tipo t2.micro, solo recursos requeridos).

---

## Histórico inicial

### [2026-04-26]
- Inicio del repositorio.
- Creación de estructura de carpetas y primeros archivos de Terraform.
- Primeros commits de prueba y merges técnicos.

---

_Para ver el detalle de cada cambio consultar los Pull Requests enlazados._