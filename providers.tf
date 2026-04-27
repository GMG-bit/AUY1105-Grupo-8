terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Última versión mayor del proveedor
    }
  }
}

provider "aws" {
  region = var.aws_region
}
