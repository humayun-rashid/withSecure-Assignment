data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  keep_rule = {
    rulePriority = 1
    description  = "Keep last ${var.lifecycle_keep} images"
    selection = merge(
      var.lifecycle_tag_prefixes == [] ?
      { tagStatus = "any" } :
      { tagStatus = "tagged", tagPrefixList = var.lifecycle_tag_prefixes },
      { countType = "imageCountMoreThan", countNumber = var.lifecycle_keep }
    )
    action = { type = "expire" }
  }

  untagged_rule = {
    rulePriority = 2
    description  = "Expire untagged > ${var.lifecycle_untagged_days} days"
    selection = {
      tagStatus   = "untagged"
      countType   = "sinceImagePushed"
      countUnit   = "days"
      countNumber = var.lifecycle_untagged_days
    }
    action = { type = "expire" }
  }

  lifecycle_rules = var.lifecycle_expire_untagged
    ? [local.keep_rule, local.untagged_rule]
    : [local.keep_rule]
}

resource "aws_ecr_repository" "this" {
  name                 = var.repo_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  dynamic "encryption_configuration" {
    for_each = var.kms_key_arn == null ? [1] : []
    content {
      encryption_type = "AES256"
    }
  }

  dynamic "encryption_configuration" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      encryption_type = "KMS"
      kms_key         = var.kms_key_arn
    }
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = jsonencode({ rules = local.lifecycle_rules })
}

resource "aws_ecr_repository_policy" "this" {
  count      = var.repository_policy_json == null ? 0 : 1
  repository = aws_ecr_repository.this.name
  policy     = var.repository_policy_json
}

# Account-level registry scanning (optional)
resource "aws_ecr_registry_scanning_configuration" "this" {
  count     = var.enable_registry_scan ? 1 : 0
  scan_type = var.registry_scan_type

  rule {
    scan_frequency = var.registry_scan_frequency
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}
