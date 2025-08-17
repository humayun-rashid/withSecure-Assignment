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
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "Region where this repo lives"
  value       = data.aws_region.current.id
}

output "docker_login" {
  description = "Docker login command"
  value       = "aws ecr get-login-password --region ${data.aws_region.current.id} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com"
}

output "docker_push_example" {
  description = "Example build/tag/push commands"
  value = join("\n", [
    "docker build -t ${aws_ecr_repository.this.name}:<tag> .",
    "docker tag ${aws_ecr_repository.this.name}:<tag> ${aws_ecr_repository.this.repository_url}:<tag>",
    "docker push ${aws_ecr_repository.this.repository_url}:<tag>"
  ])
}
