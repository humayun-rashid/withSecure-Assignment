output "alb_dns" {
  description = "Application Load Balancer DNS"
  value       = module.alb.alb_dns
}

output "tg_arn" {
  description = "Target group ARN (for debugging)"
  value       = module.alb.tg_arn
}
