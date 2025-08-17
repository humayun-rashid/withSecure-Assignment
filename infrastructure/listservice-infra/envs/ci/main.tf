terraform {
  required_version = ">= 1.6"
}



locals {
  name = "listservice-${var.env}"
  tags = { Project = "ListService", Env = var.env }
}

module "network" {
  source               = "../../modules/network"
  name                 = local.name
  vpc_cidr             = "10.10.0.0/16"
  public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]
  tags                 = local.tags
}

module "alb" {
  source            = "../../modules/alb"
  name              = local.name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  target_port       = 80
  health_check_path = "/"
  tags              = local.tags
}
module "ecs" {
  source = "../../modules/ecs"
  name   = local.name
  vpc_id = module.network.vpc_id
  # use PUBLIC subnets for CI so the task has internet via the IGW
  private_subnet_ids = module.network.public_subnet_ids
  service_sg_ingress = [module.alb.alb_sg_id]
  container_image    = var.container_image
  container_port     = 80
  cpu                = 256
  memory             = 512
  desired_count      = 1
  min_capacity       = 1
  max_capacity       = 2
  target_group_arn   = module.alb.tg_arn
  tags               = local.tags
}


module "obs" {
  source  = "../../modules/observability"
  name    = local.name
  alb_arn = module.alb.alb_arn
  tags    = local.tags
}
