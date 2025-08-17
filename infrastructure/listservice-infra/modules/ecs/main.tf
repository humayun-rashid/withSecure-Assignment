data "aws_region" "current" {}

# ECS Cluster with Container Insights
resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, { Name = "${var.name}-cluster" })
}

# Log group for ECS tasks
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

# IAM trust policy for ECS tasks
data "aws_iam_policy_document" "task_exec_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Execution role
resource "aws_iam_role" "task_execution" {
  name_prefix        = "${var.name}-exec-role-"
  assume_role_policy = data.aws_iam_policy_document.task_exec_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "exec_attach" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Optional extra policies for pulling from ECR, using Secrets Manager, etc.
resource "aws_iam_role_policy_attachment" "extra_exec_policies" {
  count      = length(var.extra_exec_role_policies)
  role       = aws_iam_role.task_execution.name
  policy_arn = var.extra_exec_role_policies[count.index]
}

# Task role (application-level permissions)
resource "aws_iam_role" "task_role" {
  name_prefix        = "${var.name}-task-role-"
  assume_role_policy = data.aws_iam_policy_document.task_exec_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "extra_task_policies" {
  count      = length(var.extra_task_role_policies)
  role       = aws_iam_role.task_role.name
  policy_arn = var.extra_task_role_policies[count.index]
}

# Task definition
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name}-task"
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app",
      image     = var.container_image,
      essential = true,
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name,
          awslogs-region        = data.aws_region.current.id,
          awslogs-stream-prefix = "app"
        }
      },
      environment = var.environment
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = var.tags
}

# ECS Service SG
resource "aws_security_group" "svc" {
  name        = "${var.name}-svc-sg"
  description = "ECS service"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.service_sg_ingress
    content {
      description     = "from alb"
      from_port       = var.container_port
      to_port         = var.container_port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# ECS Service
resource "aws_ecs_service" "this" {
  name            = "${var.name}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.svc.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = var.container_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 30

  dynamic "deployment_circuit_breaker" {
    for_each = var.enable_circuit_breaker ? [1] : []
    content {
      enable   = true
      rollback = true
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [desired_count] # let autoscaling adjust
  }
}

# Autoscaling target
resource "aws_appautoscaling_target" "svc" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.this]
}

# CPU-based autoscaling
resource "aws_appautoscaling_policy" "cpu_policy" {
  name               = "${var.name}-cpu-tt"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.svc.resource_id
  scalable_dimension = aws_appautoscaling_target.svc.scalable_dimension
  service_namespace  = aws_appautoscaling_target.svc.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.cpu_target_value
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# Request-based autoscaling (optional)
resource "aws_appautoscaling_policy" "alb_req_policy" {
  count              = var.enable_alb_scaling ? 1 : 0
  name               = "${var.name}-req-tt"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.svc.resource_id
  scalable_dimension = aws_appautoscaling_target.svc.scalable_dimension
  service_namespace  = aws_appautoscaling_target.svc.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = var.alb_target_label
    }
    target_value       = var.request_target_value
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
