########################################
# Network
########################################
module "network" {
  source               = "../../modules/network"
  name                 = local.name
  vpc_cidr             = "10.10.0.0/16"
  public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]

  tags = local.tags
}

########################################
# Application Load Balancer (HTTP only for CI)
########################################
module "alb" {
  source            = "../../modules/alb"
  name              = local.name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids

  target_port       = 8080
  health_check_path = "/health"

  enable_https           = false   # CI = no TLS
  redirect_http_to_https = false   # keep HTTP only

  tags = local.tags
}

########################################
# ECS Cluster + Service
########################################
module "ecs" {
  source = "../../modules/ecs"
  name   = local.name
  vpc_id = module.network.vpc_id

  # In CI we put ECS tasks in PUBLIC subnets (no NAT needed)
  private_subnet_ids = module.network.public_subnet_ids

  # Only ALB SG can hit service SG
  service_sg_ingress = [module.alb.alb_sg_id]

  container_image = var.container_image
  container_port  = 8080

  cpu           = 256
  memory        = 512
  desired_count = 1
  min_capacity  = 1
  max_capacity  = 2

  target_group_arn = module.alb.tg_arn

  assign_public_ip = true # CI convenience

  tags = local.tags
}

########################################
# Observability (CloudWatch Alarms)
########################################
module "obs" {
  source       = "../../modules/observability"
  name         = local.name
  alb_arn      = module.alb.alb_arn
  cluster_name = module.ecs.cluster_name
  ecs_service  = module.ecs.service_name

  tags = local.tags
}
