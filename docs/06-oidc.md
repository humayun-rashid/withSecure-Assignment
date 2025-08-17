# 6. GitHub OIDC Setup

We use **GitHub → AWS OIDC federation** instead of static credentials.

## Script
- Creates OIDC provider for `token.actions.githubusercontent.com`.
- IAM role (`ListService-<ENV>-Deploy`) with trust policy for repo/env.
- Inline policies:
  - S3 + DynamoDB for Terraform state/locks.
  - ECR push/pull access.
  - ECS/CloudWatch read access.

## Outputs
- IAM Role ARN.
- S3 state bucket path.
- DynamoDB lock table.

## Usage
In GitHub Actions:

```yaml
- name: Configure AWS credentials via OIDC
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/ListService-CI-Deploy
    aws-region: eu-central-1
