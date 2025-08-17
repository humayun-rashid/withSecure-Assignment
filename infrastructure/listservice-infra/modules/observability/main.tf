# Example: ALB 5XX alarm (simple starter)
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  # LoadBalancer dimension expects the 'app/xxx/yyyy' part of ARN
  dimensions = {
    LoadBalancer = split("/", var.alb_arn)[1]
  }

  tags = var.tags
}
