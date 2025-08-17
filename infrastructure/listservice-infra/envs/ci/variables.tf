variable "region" {
  description = "AWS region for deployment"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile for local runs. Leave empty in CI."
  type        = string
  default     = ""
}

variable "env" {
  description = "Environment name (ci, staging, prod)"
  type        = string
}

variable "container_image" {
  description = "Full container image (with tag or digest) to deploy"
  type        = string
}
