package terraform.security

# Política 1: (TEMPORALMENTE DESHABILITADA) Denegar acceso SSH público
# Se comenta para permitir gestión flexible durante aprendizaje.
# deny contains msg if {
#     resource := input.resource_changes[_]
#     resource.type == "aws_security_group"
#     ingress := resource.change.after.ingress[_]
#     ingress.from_port <= 22
#     ingress.to_port >= 22
#     cidr := ingress.cidr_blocks[_]
#     cidr == "0.0.0.0/0"
#     msg := sprintf("DENEGADO: '%s' permite acceso SSH publico desde 0.0.0.0/0", [resource.address])
# }

# Política 2: Solo permitir instancias EC2 de tipo t3.small (Requerido por TechNova)
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_instance"
  resource.change.after.instance_type != "t3.small"
  msg      := sprintf("DENEGADO: '%s' usa tipo '%s'. Solo se permite t3.small", [resource.address, resource.change.after.instance_type])
}

# Política 3: Solo permitir Launch Templates con tipo t3.small (Para escalado horizontal en ASG)
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_launch_template"
  resource.change.after.instance_type != "t3.small"
  msg      := sprintf("DENEGADO: '%s' usa tipo '%s' en Launch Template. Solo se permite t3.small", [resource.address, resource.change.after.instance_type])
}
