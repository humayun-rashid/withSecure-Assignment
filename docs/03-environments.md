# 3. Environments

Infra supports **multiple environments**: `ci`, `staging`, `prod`.

## CI
- Tasks in **public subnets** (no NAT).
- HTTP-only ALB.
- Min cost: 1 task, ALB, CloudWatch logs.
- Used for dev/test automation.

## Staging
- Tasks in **private subnets** (via NAT).
- HTTPS-enabled ALB (ACM cert + custom domain).
- Autoscaling enabled.
- Logs & alarms active.

## Production
- Same as staging, but with:
  - Higher capacity.
  - Multi-AZ redundancy.
  - Stronger autoscaling thresholds.
  - Enhanced alarms (pager duty/Slack via SNS).

## Creating a New Env
- Copy `envs/ci/` → `envs/<new-env>/`.
- Update:
  - `terraform.tfvars` (`env`, `container_image`).
  - Backend config (`backend.hcl`).
- Run `terraform init` and apply.
