terraform {
  required_version = ">= 1.6"

  backend "s3" {
    bucket         = "tf-state-920120424372-eu-central-1"
    key            = "listservice/ci/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf-state-lock"
    encrypt        = true
    profile        = "sandbox"
  }
}
