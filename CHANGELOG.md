# Changelog

Todas las modificaciones importantes de este proyecto se documentarán en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/)
y las versiones se ordenan de la más reciente a la más antigua.

---

## [Unreleased]

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