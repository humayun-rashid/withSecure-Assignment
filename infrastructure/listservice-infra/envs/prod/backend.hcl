# TODO: replace <your-account-id> and region if different
bucket         = "tf-state-<your-account-id>-eu-central-1"
key            = "listservice/prd/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "tf-state-lock"
encrypt        = true
profile        = "sandbox"
