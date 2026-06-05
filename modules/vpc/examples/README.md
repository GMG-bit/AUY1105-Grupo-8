# Ejemplo de uso — Módulo VPC

Este ejemplo despliega una VPC completa con subredes públicas y privadas
distribuidas en dos zonas de disponibilidad, junto con Internet Gateway,
NAT Gateway y las tablas de ruteo asociadas.

## Objetivo

Demostrar cómo invocar el módulo `vpc` con un conjunto mínimo de parámetros y
obtener los identificadores (VPC y subredes) que consumen los demás módulos
(cómputo, base de datos y balanceador).

## Cómo usarlo

```bash
cd basico
terraform init
terraform plan
terraform apply
```

Para destruir los recursos creados por el ejemplo:

```bash
terraform destroy
```

## Parámetros utilizados

| Variable               | Descripción                                  | Valor del ejemplo                     |
|------------------------|----------------------------------------------|---------------------------------------|
| `project_name`         | Nombre del proyecto para etiquetar recursos  | `ejemplo-technova`                    |
| `vpc_cidr_block`       | Rango de IPs de la VPC                        | `10.1.0.0/16`                         |
| `public_subnet_cidrs`  | CIDRs de las subredes públicas               | `["10.1.1.0/24", "10.1.2.0/24"]`      |
| `private_subnet_cidrs` | CIDRs de las subredes privadas               | `["10.1.101.0/24", "10.1.102.0/24"]`  |

## Salidas

| Output               | Descripción                          |
|----------------------|--------------------------------------|
| `vpc_id`             | ID de la VPC creada                  |
| `public_subnet_ids`  | Lista de IDs de subredes públicas    |
| `private_subnet_ids` | Lista de IDs de subredes privadas    |

> Requiere credenciales AWS válidas con permisos sobre VPC, EC2 (subredes,
> gateways) y CloudWatch Logs (VPC Flow Logs).
