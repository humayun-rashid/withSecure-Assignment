variable "repo_name" {
  description = "ECR repository name (unique per account/region)"
  type        = string
  default     = "listservice-global"
}

variable "image_tag_mutability" {
  description = "IMMUTABLE or MUTABLE"
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "Enable repository-level image scanning on push"
  type        = bool
  default     = true
}

variable "force_delete" {
  description = "Allow delete even if images exist"
  type        = bool
  default     = true
}

variable "lifecycle_keep" {
  description = "Keep the most recent N images (tagStatus=any rule)"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    Project = "ListService"
    Env     = "global"
    Managed = "terraform"
  }
}
