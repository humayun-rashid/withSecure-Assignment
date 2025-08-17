output "ecr_repository_name" {
  description = "Repository name"
  value       = aws_ecr_repository.this.name
}

output "ecr_repository_url" {
  description = "Fully qualified ECR repo URL"
  value       = aws_ecr_repository.this.repository_url
}

output "ecr_repository_arn" {
  description = "Repository ARN"
  value       = aws_ecr_repository.this.arn
}

output "registry_id" {
  description = "AWS account (registry) ID"
  value       = aws_ecr_repository.this.registry_id
}

output "region" {
  description = "Region where this repo lives"
  value       = data.aws_region.current.name
}

# Convenience strings for quick copy/paste in CI or locally
output "login_command" {
  description = "Docker login command for this region"
  value       = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

output "push_example" {
  description = "Example tag/push commands"
  value       = join("\n", [
    "docker build -t ${aws_ecr_repository.this.name}:<tag> .",
    "docker tag ${aws_ecr_repository.this.name}:<tag> ${aws_ecr_repository.this.repository_url}:<tag>",
    "docker push ${aws_ecr_repository.this.repository_url}:<tag>"
  ])
}
