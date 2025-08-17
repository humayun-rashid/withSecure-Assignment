variable "region" {
  type        = string
  description = "AWS region for deployment"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile"
}

variable "env" {
  type        = string
  description = "Environment name (ci, staging, prod)"
}

variable "container_image" {
  type        = string
  description = "Container image (with tag or digest) to deploy"
}
