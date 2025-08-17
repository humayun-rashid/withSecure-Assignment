variable "repo_name" {
  description = "ECR repository name (must be unique in the account/region)"
  type        = string
}

variable "image_tag_mutability" {
  description = "IMMUTABLE or MUTABLE"
  type        = string
  default     = "IMMUTABLE"
  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be IMMUTABLE or MUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push (repository level)"
  type        = bool
  default     = true
}

variable "force_delete" {
  description = "Allow deleting a repo even if it contains images"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Optional KMS CMK ARN for encryption. If null, SSE-S3 (AES256) is used."
  type        = string
  default     = null
}

variable "lifecycle_keep" {
  description = "Keep the most recent N images (using imageCountMoreThan)"
  type        = number
  default     = 20
}

variable "lifecycle_tag_prefixes" {
  description = "Optional list of tag prefixes to scope the keep-N rule. Empty = apply to any tag status."
  type        = list(string)
  default     = []
}

variable "lifecycle_expire_untagged" {
  description = "If true, expire untagged images older than lifecycle_untagged_days"
  type        = bool
  default     = true
}

variable "lifecycle_untagged_days" {
  description = "Days after which untagged images are expired (since push)"
  type        = number
  default     = 7
}

variable "repository_policy_json" {
  description = "Optional JSON string for aws_ecr_repository_policy (e.g., cross-account permissions)"
  type        = string
  default     = null
}

variable "enable_registry_scan" {
  description = "If true, enables BASIC registry scanning at account level (idempotent)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
