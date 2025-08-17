output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns" {
  value = aws_lb.this.dns_name
}

output "tg_arn" {
  value = aws_lb_target_group.this.arn
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "listener_http_arn" {
  value = aws_lb_listener.http.arn
}

output "listener_https_arn" {
  value = try(aws_lb_listener.https[0].arn, null)
}
