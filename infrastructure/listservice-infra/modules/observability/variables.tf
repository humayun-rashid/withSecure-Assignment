variable "name" { type = string }

variable "alb_arn" {
  type        = string
  description = "ALB ARN (used for alarms)"
}

variable "enable_alb_4xx_alarm" {
  type    = bool
  default = false
}

variable "enable_alb_latency_alarm" {
  type    = bool
  default = false
}

variable "cluster_name" {
  type        = string
  description = "ECS cluster name"
}

variable "ecs_service" {
  type        = string
  description = "ECS service name"
}

variable "ecs_high_cpu_threshold" {
  type        = number
  default     = 80
  description = "CPU threshold for ECS high CPU alarm"
}

variable "tags" {
  type    = map(string)
  default = {}
}
