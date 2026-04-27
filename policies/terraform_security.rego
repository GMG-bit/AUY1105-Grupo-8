package terraform.security

# Política 1: Denegar acceso SSH público desde cualquier IP (0.0.0.0/0)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    ingress := resource.change.after.ingress[_]
    ingress.from_port <= 22
    ingress.to_port >= 22
    cidr := ingress.cidr_blocks[_]
    cidr == "0.0.0.0/0"
    msg := sprintf("DENEGADO: '%s' permite acceso SSH publico desde 0.0.0.0/0", [resource.address])
}

# Política 2: Solo permitir instancias EC2 de tipo t2.micro
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    resource.change.after.instance_type != "t2.micro"
    msg := sprintf("DENEGADO: '%s' usa tipo '%s'. Solo se permite t2.micro", [resource.address, resource.change.after.instance_type])
}
