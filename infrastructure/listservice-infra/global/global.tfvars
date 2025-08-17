repo_name               = "listservice-global"
image_tag_mutability    = "MUTABLE"   # <-- important
lifecycle_keep          = 15
lifecycle_untagged_days = 5
tags = {
  Environment = "global"
  Service     = "listservice"
}
