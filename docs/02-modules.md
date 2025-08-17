# 2. Terraform Modules

The infra is modular: each component is defined in `../../modules`.

## 🔹 `network`
- Creates VPC, public/private subnets, route tables.
- Internet Gateway for public subnets.
- NAT Gateway for private subnets (staging/prod).
- Outputs: `vpc_id`, `public_subnet_ids`, `private_subnet_ids`.

## 🔹 `alb`
- Creates ALB, security group, target group, listeners.
- Default = HTTP; optional HTTPS with ACM certificate.
- Outputs: `alb_dns`, `tg_arn`, `alb_sg_id`.

## 🔹 `ecs`
- Creates ECS cluster + service.
- Task definition (CPU/memory, image, port).
- IAM roles (execution + task).
- Security group for ECS tasks.
- Optional autoscaling policies.
- Outputs: `cluster_name`, `service_name`, `task_definition_arn`.

## 🔹 `ecr`
- ECR repository for container images.
- Lifecycle policies (expire old images).
- Outputs: `ecr_repository_url`.

## 🔹 `autoscaling`
- Scaling target and policies:
  - CPU utilization scaling.
  - Request count scaling.
- ECS module already integrates basics.

## 🔹 `observability`
- CloudWatch alarms:
  - ALB 5xx
  - ECS high CPU
  - ECS running task count < 1
- Optional 4xx & latency alarms.
- Outputs: alarm ARNs and names.
