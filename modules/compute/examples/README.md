# Ejemplo de uso — Módulo de Cómputo

Este ejemplo despliega la capa de cómputo de alta disponibilidad: un
**Launch Template** y un **Auto Scaling Group** distribuidos en dos subredes
públicas, sobre una VPC creada con el módulo `vpc`.

## Objetivo

Mostrar cómo integrar el módulo `compute` con la red base y un Security Group,
parametrizando capacidad mínima/deseada/máxima del ASG.

## Cómo usarlo

```bash
cd basico
terraform init
terraform apply \
  -var="key_name=mi-keypair" \
  -var="target_group_arn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/ejemplo/abc123" \
  -var="assets_bucket_id=mi-bucket-assets"
```

Para destruir:

```bash
terraform destroy
```

## Parámetros del módulo

| Variable             | Descripción                                                 | Requerido |
|----------------------|-------------------------------------------------------------|-----------|
| `project_name`       | Nombre del proyecto para etiquetar recursos                 | Sí        |
| `subnet_ids`         | IDs de subredes donde se lanzan las instancias              | Sí        |
| `security_group_ids` | Security Groups asociados a las instancias                  | Sí        |
| `key_name`           | Par de claves EC2 para acceso SSH                           | Sí        |
| `target_group_arn`   | ARN del Target Group del ALB al que se registra el ASG      | Sí        |
| `assets_bucket_id`   | ID del bucket S3 con los archivos estáticos                 | Sí        |
| `aws_region`         | Región de AWS                                               | Sí        |
| `desired_capacity`   | Cantidad deseada de instancias (default `1`)                | No        |
| `min_size`           | Mínimo de instancias (default `1`)                          | No        |
| `max_size`           | Máximo de instancias (default `3`)                          | No        |

## Salidas

| Output               | Descripción                          |
|----------------------|--------------------------------------|
| `asg_name`           | Nombre del Auto Scaling Group        |
| `launch_template_id` | ID de la Launch Template             |

> **Nota sobre los outputs:** este módulo usa un Auto Scaling Group, por lo que
> no existe un `instance_id`/`instance_ip` único. Los identificadores de las
> instancias se obtienen dinámicamente desde el ASG (`asg_name`). Si se requiere
> el patrón clásico `instance_id`/`instance_ip` para una instancia individual,
> debe usarse un `aws_instance` en lugar del ASG.
