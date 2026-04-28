# Changelog
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
- Agregado pipeline CI/CD con GitHub Actions ([#6](https://github.com/GMG-bit/AUY1105-Grupo-8/pull/6)):
  - Incluye TFLint, Checkov, Terraform Validate y tests con OPA.

### Cambios
- Limpieza y ajuste de la infraestructura Terraform para EP1 ([#8](https://github.com/GMG-bit/AUY1105-Grupo-8/pull/8)):
  - Eliminación de módulos (ALB, backend_servers, RDS, S3+CloudFront) y archivos estáticos innecesarios.
  - Corrección de bug en outputs y variables.
  - Prefijos `AUY1105-` agregados en recursos VPC.
  - Providers y variables renovados y alineados.
  - Mejoras de seguridad: sólo acceso SSM a instancias, egress restringido, disco cifrado, Flow Logs con KMS.
  - Descripción de justificaciones de skips para chequeos automáticos de seguridad.

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