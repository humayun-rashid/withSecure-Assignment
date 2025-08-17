terraform {
  required_version = ">= 1.6.0"

  # Real values come from backend.hcl at init-time
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
