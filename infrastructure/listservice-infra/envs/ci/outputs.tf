output "alb_dns" {
  description = "Application Load Balancer DNS"
  value       = module.alb.alb_dns
}

output "tg_arn" {
  description = "Target group ARN (for debugging)"
  value       = module.alb.tg_arn
}

output "ecs_cluster" {
  description = "ECS Cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service" {
  description = "ECS Service name"
  value       = module.ecs.service_name
}
