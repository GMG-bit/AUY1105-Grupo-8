package terraform.security_test

import data.terraform.security

# ---- Escenario 1: Plan valido (debe pasar sin denials) ----
test_plan_valido_sin_denials if {
    count(security.deny) == 0 with input as {
        "resource_changes": [
            {
                "type": "aws_instance",
                "address": "aws_instance.server",
                "change": {
                    "actions": ["create"],
                    "after": {
                        "instance_type": "t2.micro"
                    }
                }
            },
            {
                "type": "aws_security_group",
                "address": "aws_security_group.servers_sg",
                "change": {
                    "actions": ["create"],
                    "after": {
                        "ingress": [
                            {
                                "from_port": 22,
                                "to_port": 22,
                                "protocol": "tcp",
                                "cidr_blocks": ["10.1.0.0/16"]
                            }
                        ]
                    }
                }
            }
        ]
    }
}

# ---- Escenario 2: SSH desde 0.0.0.0/0 debe ser denegado ----
test_ssh_publico_denegado if {
    count(security.deny) > 0 with input as {
        "resource_changes": [
            {
                "type": "aws_security_group",
                "address": "aws_security_group.servers_sg",
                "change": {
                    "actions": ["create"],
                    "after": {
                        "ingress": [
                            {
                                "from_port": 22,
                                "to_port": 22,
                                "protocol": "tcp",
                                "cidr_blocks": ["0.0.0.0/0"]
                            }
                        ]
                    }
                }
            }
        ]
    }
}

# ---- Escenario 3: Instancia no t2.micro debe ser denegada ----
test_instancia_no_t2micro_denegada if {
    count(security.deny) > 0 with input as {
        "resource_changes": [
            {
                "type": "aws_instance",
                "address": "aws_instance.server",
                "change": {
                    "actions": ["create"],
                    "after": {
                        "instance_type": "t2.large"
                    }
                }
            }
        ]
    }
}
