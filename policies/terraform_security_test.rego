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
            "instance_type": "t3.small"
          }
        }
      },
      {
        "type": "aws_launch_template",
        "address": "aws_launch_template.app_lt",
        "change": {
          "actions": ["create"],
          "after": {
            "instance_type": "t3.small"
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

# ---- Escenario 2: Instancia no t3.small debe ser denegada ----
test_instancia_no_t3small_denegada if {
  count(security.deny) > 0 with input as {
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
      }
    ]
  }
}

# ---- Escenario 3: Launch Template no t3.small debe ser denegado ----
test_launch_template_no_t3small_denegado if {
  count(security.deny) > 0 with input as {
    "resource_changes": [
      {
        "type": "aws_launch_template",
        "address": "aws_launch_template.app_lt",
        "change": {
          "actions": ["create"],
          "after": {
            "instance_type": "t2.micro"
          }
        }
      }
    ]
  }
}
