variable "name" {
  description = "Prefix for resources"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "service_name" {
  description = "ECS service name"
  type        = string
}

variable "enable_alb_scaling" {
  description = "Enable ALB request count based scaling"
  type        = bool
  default     = false
}

variable "alb_target_label" {
  description = "ALB target group label for RequestCount scaling (format: app/xxx/yyyy/targetgroup/zzz/aaa)"
  type        = string
  default     = null
}

variable "cpu_target_value" {
  description = "Target CPU utilization for scaling"
  type        = number
  default     = 60
}

variable "alb_req_target_value" {
  description = "Target ALB requests per target for scaling"
  type        = number
  default     = 100
}

variable "scale_in_cooldown" {
  description = "Cooldown in seconds for scale in"
  type        = number
  default     = 60
}

variable "scale_out_cooldown" {
  description = "Cooldown in seconds for scale out"
  type        = number
  default     = 60
}

variable "min_capacity" {
  description = "Minimum ECS task count"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum ECS task count"
  type        = number
  default     = 4
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
