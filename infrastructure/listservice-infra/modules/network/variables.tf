variable "name" {
  description = "Prefix for all network resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets (must match number of AZs you want to use)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets (must match number of AZs you want to use)"
  type        = list(string)
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Deploy NAT Gateway for private subnets"
  type        = bool
  default     = false # CI: false, Prod/Staging: true
}

variable "enable_s3_endpoint" {
  description = "Enable S3 VPC Gateway endpoint"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default     = {}
}
