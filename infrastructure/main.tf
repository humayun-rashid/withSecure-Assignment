provider "aws" {
  region  = "eu-north-1"
  profile = "sandbox" # the profile you configured earlier
}

# Fetch account info (to make bucket name unique)
data "aws_caller_identity" "me" {}

resource "aws_s3_bucket" "test_bucket" {
  bucket        = "sandbox-tf-${data.aws_caller_identity.me.account_id}"
  force_destroy = true   # allows automatic cleanup even if objects exist
}

output "bucket_name" {
  value = aws_s3_bucket.test_bucket.bucket
}
