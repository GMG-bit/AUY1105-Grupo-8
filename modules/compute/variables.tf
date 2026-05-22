variable "project_name" {}
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "key_name" {}
variable "target_group_arn" {}
variable "desired_capacity" { default = 1 }
variable "min_size" { default = 1 }
variable "max_size" { default = 3 }

variable "assets_bucket_id" {
  description = "ID del bucket S3 que contiene los archivos estaticos del sitio"
  type        = string
}

variable "aws_region" {
  description = "Region de AWS donde se despliegan los recursos"
  type        = string
}