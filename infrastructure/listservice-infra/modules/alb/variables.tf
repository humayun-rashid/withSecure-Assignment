variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "target_port" {
  type    = number
  default = 8080
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "health_check_matcher" {
  type    = string
  default = "200-399"
}

variable "enable_https" {
  type    = bool
  default = false
}

variable "redirect_http_to_https" {
  type    = bool
  default = false
}

variable "certificate_arn" {
  type        = string
  default     = null
  description = "ACM certificate ARN for HTTPS"
}

variable "ssl_policy" {
  type        = string
  default     = "ELBSecurityPolicy-2016-08"
}

variable "enable_access_logs" {
  type    = bool
  default = false
}

variable "access_logs_bucket" {
  type        = string
  default     = null
  description = "S3 bucket for ALB access logs"
}

variable "access_logs_prefix" {
  type    = string
  default = null
}

variable "allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
