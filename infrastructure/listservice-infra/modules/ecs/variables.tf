variable "name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "service_sg_ingress" {
  type        = set(string)
  description = "Security group IDs allowed to connect to ECS service"
  default     = []
}

variable "container_image" { type = string }
variable "target_group_arn" { type = string }

variable "container_port" {
  type    = number
  default = 8080
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "min_capacity" {
  type    = number
  default = 2
}

variable "max_capacity" {
  type    = number
  default = 4
}

variable "assign_public_ip" {
  type        = bool
  default     = true
  description = "CI convenience; must be false in prod/staging"
}

variable "log_retention_in_days" {
  type        = number
  default     = 14
  description = "Retention period (days) for ECS logs; increase in prod"
}

variable "enable_circuit_breaker" {
  type    = bool
  default = true
}

variable "cpu_target_value" {
  type    = number
  default = 60
}

variable "enable_alb_scaling" {
  type    = bool
  default = false
}

variable "alb_target_label" {
  type        = string
  description = "Format: app/<LB-name>/<LB-id>/targetgroup/<TG-name>/<TG-id> (from ALB module output)"
  default     = null
}

variable "request_target_value" {
  type    = number
  default = 100
}

variable "extra_exec_role_policies" {
  type    = list(string)
  default = []
}

variable "extra_task_role_policies" {
  type    = list(string)
  default = []
}

variable "environment" {
  type = list(object({
    name  = string
    value = string
  }))
  default     = []
  description = "Environment variables for the container"
}

variable "tags" {
  type    = map(string)
  default = {}
}
