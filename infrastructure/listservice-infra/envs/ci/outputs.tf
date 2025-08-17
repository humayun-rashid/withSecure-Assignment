output "alb_dns" {
  value = module.alb.alb_dns
}

# (handy for debugging)
output "tg_arn" {
  value = module.alb.tg_arn
}
