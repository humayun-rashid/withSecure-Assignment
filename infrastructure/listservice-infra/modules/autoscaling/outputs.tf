output "scaling_target_id" {
  value = aws_appautoscaling_target.ecs.id
}

output "cpu_policy_name" {
  value = aws_appautoscaling_policy.cpu.name
}

output "alb_req_policy_name" {
  value = try(aws_appautoscaling_policy.alb_req[0].name, null)
}
