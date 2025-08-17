# --- ALB 5xx ---
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

  dimensions = {
    LoadBalancer = split("/", var.alb_arn)[1]
  }

  tags = var.tags
}

# --- ALB 4xx (optional) ---
resource "aws_cloudwatch_metric_alarm" "alb_4xx" {
  count               = var.enable_alb_4xx_alarm ? 1 : 0
  alarm_name          = "${var.name}-alb-4xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 100
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = split("/", var.alb_arn)[1]
  }

  tags = var.tags
}

# --- ALB Latency (optional) ---
resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  count               = var.enable_alb_latency_alarm ? 1 : 0
  alarm_name          = "${var.name}-alb-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0.5 # seconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = split("/", var.alb_arn)[1]
  }

  tags = var.tags
}

# --- ECS High CPU ---
resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "${var.name}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.ecs_high_cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.ecs_service
  }

  tags = var.tags
}

# --- ECS Low Running Tasks ---
resource "aws_cloudwatch_metric_alarm" "ecs_low_running" {
  alarm_name          = "${var.name}-ecs-low-running"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.ecs_service
  }

  tags = var.tags
}
