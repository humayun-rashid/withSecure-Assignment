locals {
  name = "listservice-${var.env}"
  tags = {
    Project     = "ListService"
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

# --- Network ---
module "network" {
  source               = "../../modules/network"
  name                 = local.name
  vpc_cidr             = "10.10.0.0/16"
  public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]
  tags                 = local.tags
}

# --- ALB ---
module "alb" {
  source            = "../../modules/alb"
  name              = local.name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids

  # Must match your container
  target_port       = 8080
  health_check_path = "/health"

  tags = local.tags
}

# --- ECS Service ---
module "ecs" {
  source = "../../modules/ecs"
  name   = local.name
  vpc_id = module.network.vpc_id

  # CI: place tasks in PUBLIC subnets for outbound internet via IGW
  private_subnet_ids = module.network.public_subnet_ids

  # Allow ingress only from ALB SG
  service_sg_ingress = [module.alb.alb_sg_id]

  container_image = var.container_image
  container_port  = 8080

  cpu           = 256
  memory        = 512
  desired_count = 1
  min_capacity  = 1
  max_capacity  = 2

  target_group_arn = module.alb.tg_arn

  tags = local.tags
}

# --- Observability ---
module "obs" {
  source  = "../../modules/observability"
  name    = local.name
  alb_arn = module.alb.alb_arn
  tags    = local.tags
}
