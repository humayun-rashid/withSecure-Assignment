data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ECR repository
resource "aws_ecr_repository" "this" {
  name                 = var.repo_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = var.tags
}

# ECR lifecycle policy
# IMPORTANT: ECR requires the "tagStatus=any" rule to have the LOWEST priority.
# Since we only have one rule, we use priority 2 to be future-proof.
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 2
        description  = "Keep last ${var.lifecycle_keep} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.lifecycle_keep
        }
        action = { type = "expire" }
      }
    ]
  })
}
