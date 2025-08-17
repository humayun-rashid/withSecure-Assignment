region = "eu-central-1"

# For local runs only. In CI this should remain empty (default = "").
aws_profile = "sandbox"

env = "ci"

# Image pushed by CI/CD. 
# Use :ci or :latest depending on your workflow.
container_image = "920120424372.dkr.ecr.eu-central-1.amazonaws.com/listservice-global:ci"
