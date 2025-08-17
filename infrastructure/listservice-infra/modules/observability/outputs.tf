# ALB
output "alb_5xx_alarm_name" {
  value = aws_cloudwatch_metric_alarm.alb_5xx.alarm_name
}
output "alb_5xx_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.alb_5xx.arn
}

output "alb_4xx_alarm_name" {
  value = try(aws_cloudwatch_metric_alarm.alb_4xx[0].alarm_name, null)
}
output "alb_latency_alarm_name" {
  value = try(aws_cloudwatch_metric_alarm.alb_latency[0].alarm_name, null)
}

# ECS
output "ecs_high_cpu_alarm_name" {
  value = aws_cloudwatch_metric_alarm.ecs_high_cpu.alarm_name
}
output "ecs_high_cpu_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.ecs_high_cpu.arn
}

output "ecs_low_running_alarm_name" {
  value = aws_cloudwatch_metric_alarm.ecs_low_running.alarm_name
}
output "ecs_low_running_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.ecs_low_running.arn
}
