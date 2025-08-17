terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.region
  # Use profile only if set (local dev). In CI, leave blank so OIDC creds are used.
  profile = var.aws_profile != "" ? var.aws_profile : null
}
