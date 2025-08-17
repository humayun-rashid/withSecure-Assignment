# 4. Security

## Security Groups
- **ALB SG**: inbound 80/443 from `0.0.0.0/0`.
- **ECS SG**: inbound only from ALB SG.

## IAM Roles
- **Task execution role**: pulls from ECR, writes to logs.
- **Task role**: minimal app permissions (extend if app needs AWS APIs).
- **Terraform OIDC role**: used by GitHub Actions for deployment.

## HTTPS
- Requires domain + ACM certificate.
- ALB listener forwards 80 → 443.

## Logging & Monitoring
- ECS → CloudWatch logs.
- Alarms: ALB 5xx, ECS CPU, task count.
