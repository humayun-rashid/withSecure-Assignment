locals {
  name = "listservice-${var.env}"
  tags = {
    Project     = "ListService"
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}
